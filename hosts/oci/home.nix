{ ... }:

# Server-only home config, layered on top of home.nix and home-linux.nix.
{
  # A long-running rex server the Mac reaches at https://oci-rex.<tailnet>.ts.net. Rex runs its
  # own Tailscale node, separate from the host's. First start needs a sign-in: open the link from
  # `rex server status`. Linger (configuration.nix) keeps it running while logged out.
  services.rex = {
    enable = true;
    tailscale = {
      enable = true;
      hostname = "oci-rex";
    };
  };

  programs.ssh.settings."github.com" = {
    IdentityFile = "~/.ssh/id_ed25519_hansenzhang_github";
    IdentitiesOnly = true;
  };
}
