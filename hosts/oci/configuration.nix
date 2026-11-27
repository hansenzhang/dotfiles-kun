{ pkgs, user, ... }:

# The Oracle Cloud Ampere A1 server. Install and recovery: docs/oracle-cloud-nixos.md.
{
  imports = [ ./github-runners.nix ];

  networking.hostName = "oci";
  time.timeZone = "UTC";

  nixpkgs.config.allowUnfree = true;  # claude-code
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Lets `nixos-rebuild --target-host` from the Mac copy closures in as this user.
    trusted-users = [ "root" user ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;

  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keyFiles = [ ./authorized_keys ];
    # Starts the user's systemd services (Syncthing, claude-sessions-sync) at boot, not at login.
    linger = true;
  };
  # Key-only login and no password set, so sudo can't ask for one.
  security.sudo.wheelNeedsPassword = false;
  programs.zsh.enable = true;

  # Tailscale SSH is off, so this sshd serves port 22 on the tailnet too.
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Join once with `sudo tailscale up`; the login persists in /var/lib/tailscale.
  # openFirewall opens UDP 41641 so peers can connect directly instead of through DERP relays.
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };
  networking.firewall.allowedTCPPorts = [ 22 ];
  # 22000 is Syncthing (home.nix), which syncs only over the tailnet.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22000 ];

  # Generic Linux binaries (uv's Pythons, npm packages with prebuilt binaries) expect a normal
  # dynamic loader; nix-ld provides one.
  programs.nix-ld.enable = true;

  # potential-chainsaw's builder runs gVisor (runsc) inside a privileged container.
  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; [ git vim ];

  system.stateVersion = "26.05";
}
