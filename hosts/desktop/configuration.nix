{ lib, pkgs, user, ... }:

# Desktop dual-booting with Windows 11 on the same NVMe. Install: docs/desktop-nixos.md.
{
  imports = [ ./hardware.nix ./microvm.nix ];

  networking.hostName = "desktop";
  networking.networkmanager.enable = true;
  # Windows keeps the hardware clock in local time; match it so neither OS shifts the other's clock.
  time.hardwareClockInLocalTime = true;
  services.automatic-timezoned.enable = true;

  # systemd-boot lists Windows Boot Manager automatically. The ESP is only 512M and Windows
  # uses ~35M of it, so cap how many generations keep a kernel + initrd there.
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 3;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  nixpkgs.config.allowUnfree = true;  # nvidia, steam, claude-code
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" user ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;

  # Password set once after install (docs/desktop-nixos.md); sudo asks for it.
  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" "kvm" ];
    shell = pkgs.zsh;
    # Only the Mac's tailnet key; oci and sylve never connect in.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEO/Wf115KSSu2CyAWr7b/s5qRwbnWWpwwrBFQ6wsElU hansen@monicas-macbook-pro"
    ];
    linger = true;  # keeps the Rex user service (hosts/desktop/home.nix) running while logged out
  };
  programs.zsh.enable = true;

  # Plasma is installed but not started: boot lands on a text console, and `gui` starts the
  # login screen (`gui off` stops it). Enabling a display manager makes graphical.target the
  # default, so force it back to multi-user.
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  systemd.defaultUnit = lib.mkForce "multi-user.target";
  # The lingering user manager runs DrKonqi's crash launcher with no display, so the launcher
  # aborts in Qt init, and its own coredump starts the next launcher. On 2026-11-14 that loop
  # left 130k failed units and made the user manager too slow for activation. Mask it.
  systemd.user.units."drkonqi-coredump-launcher.socket".enable = false;
  # With a display manager enabled, NixOS keeps getty.target from starting tty1's login, so
  # boot would end on a blank tty1. Start it at boot unless the GUI already holds tty1.
  systemd.services.tty1-login = {
    wantedBy = [ "multi-user.target" ];
    after = [ "getty.target" ];
    restartIfChanged = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = "systemctl is-active -q display-manager || systemctl --no-block start autovt@tty1.service";
  };
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  hardware.bluetooth.enable = true;
  hardware.xone.enable = true;  # Xbox Wireless Adapter

  # Keep the Proton library on ext4; Steam libraries on the NTFS drives are unreliable.
  programs.steam.enable = true;
  programs.firefox.enable = true;

  # Always-on host reached over SSH: never suspend or hibernate, even when Plasma's idle timer asks.
  systemd.targets = lib.genAttrs [ "sleep" "suspend" "hibernate" "hybrid-sleep" "suspend-then-hibernate" ]
    (_: { enable = false; });

  # Join once with `sudo tailscale up` (no --ssh: OpenSSH serves port 22). SSH is reachable over the tailnet only.
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  # 22000 is Syncthing (home.nix).
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 22000 ];

  programs.nix-ld.enable = true;
  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; [
    git
    vim
    wezterm
    (writeShellApplication {
      name = "gui";
      text = ''
        case "''${1:-on}" in
          on) exec sudo systemctl start display-manager ;;
          off) sudo systemctl stop display-manager && exec sudo systemctl start autovt@tty1.service ;;
          *) echo "usage: gui [on|off]" >&2; exit 1 ;;
        esac
      '';
    })
  ];

  system.stateVersion = "26.05";
}
