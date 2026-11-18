{ ... }:

# Desktop-only home config, layered on top of home.nix and home-linux.nix.
{
  # Rex server reachable at https://desktop-rex.<tailnet>.ts.net over its own Tailscale node.
  # First start prints a sign-in link in `rex server status`; then pair other devices with
  # `rex server tailscale pair`. Lingering (configuration.nix) keeps it up while logged out.
  services.rex = {
    enable = true;
    tailscale = {
      enable = true;
      hostname = "desktop-rex";
    };
  };

  # id_ed25519_tailnet is this machine's key for the Mac, oci and sylve; id_ed25519_github is GitHub only.
  programs.ssh.settings = {
    "github.com" = {
      IdentityFile = "~/.ssh/id_ed25519_github";
      IdentitiesOnly = true;
    };
    "mac" = {
      HostName = "monicas-macbook-pro";
      User = "hansen";
      IdentityFile = "~/.ssh/id_ed25519_tailnet";
      IdentitiesOnly = true;
    };
    "oci" = {
      User = "hansen";
      IdentityFile = "~/.ssh/id_ed25519_tailnet";
      IdentitiesOnly = true;
    };
    "sylve" = {
      User = "deploy";
      IdentityFile = "~/.ssh/id_ed25519_tailnet";
      IdentitiesOnly = true;
    };
  };
}
