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
}
