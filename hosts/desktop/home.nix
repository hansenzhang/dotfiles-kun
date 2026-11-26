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

  # Hourly autoclipper poll: downloads new Zajef77 VODs, cuts the runs into clips and uploads
  # them to YouTube. It runs in the repo's flake devShell, which supplies uv, ffmpeg and the
  # nix-ld libraries. secrets.toml sets data_dir to the shared NTFS volume at /mnt/data.
  # A oneshot has no start timeout, and the timer skips a tick while the last run is busy.
  systemd.user.services.autoclipper-poll = {
    Unit.Description = "Poll Twitch and clip new VODs to YouTube";
    Service = {
      Type = "oneshot";
      WorkingDirectory = "%h/github/autoclipper";
      Environment = [ "AUTOCLIPPER_CONFIG_DIR=%h/.config/autoclipper" ];
      ExecStart = "/run/current-system/sw/bin/nix develop %h/github/autoclipper --command uv run --frozen autoclipper poll";
      Nice = 10;
    };
  };
  systemd.user.timers.autoclipper-poll = {
    Timer = { OnCalendar = "hourly"; Persistent = true; };
    Install.WantedBy = [ "timers.target" ];
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
