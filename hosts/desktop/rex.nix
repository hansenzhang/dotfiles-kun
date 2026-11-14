{ ... }:

# Rex server as a systemd user service, reachable over its own Tailscale node.
# First start prints a Tailscale sign-in link in `rex server status`; then pair other
# devices with `rex server tailscale pair`. Lingering (configuration.nix) keeps it up while logged out.
{
  services.rex = {
    enable = true;
    tailscale = {
      enable = true;
      hostname = "rex-desktop";
    };
  };
}
