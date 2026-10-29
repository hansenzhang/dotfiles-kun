{ pkgs, user, ... }:

# The Oracle Cloud Ampere A1 server. Install and recovery: docs/oracle-cloud-nixos.md.
{
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
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keyFiles = [ ./authorized_keys ];
  };
  # Key-only login and no password set, so sudo can't ask for one.
  security.sudo.wheelNeedsPassword = false;
  programs.zsh.enable = true;

  # Tailscale SSH answers port 22 on the tailnet address, so OpenSSH also listens on 2222 for
  # clients that need the real sshd there (Heeler pairing; see `ssh_port` in herdr's heeler
  # pair.json). 2222 is only opened on tailscale0; 22 stays public for the VCN security list.
  services.openssh = {
    enable = true;
    ports = [ 22 2222 ];
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Join once with `sudo tailscale up --ssh`; the login persists in /var/lib/tailscale.
  # openFirewall opens UDP 41641 so peers can connect directly instead of through DERP relays.
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 2222 ];

  # Generic Linux binaries (uv's Pythons, npm packages with prebuilt binaries) expect a normal
  # dynamic loader; nix-ld provides one.
  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [ git vim ];

  system.stateVersion = "26.05";
}
