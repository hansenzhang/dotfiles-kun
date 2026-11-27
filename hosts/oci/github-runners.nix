{ config, lib, pkgs, ... }:

# oci's runners: runner-1 for super-enigma, runner-2 for lucky-contour. The runner containers are in ../github-runners.nix.
let
  names = [ "runner-1" "runner-2" ];
in
{
  imports = [
    (import ../github-runners.nix { host = "oci"; inherit names; labels = "oci"; memory = "4g"; })
  ];

  # Cloudflare container images are linux/amd64. This registers a static qemu with the fix-binary flag,
  # so the kernel preloads it and it also runs inside Docker's build containers. Not
  # boot.binfmt.preferStaticEmulators: the binary cache lacks its static qemu, so oci would compile it from source.
  systemd.services.binfmt-amd64 = {
    description = "Register qemu for linux/amd64 binaries";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ config.virtualisation.docker.package pkgs.util-linux ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    # The kernel drops registrations when the last binfmt_misc mount goes away, so the host holds one.
    script = ''
      mountpoint -q /proc/sys/fs/binfmt_misc || mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
      docker run --rm --privileged tonistiigi/binfmt:qemu-v10.2.3-68 --install amd64
    '';
  };

  # Jobs leave images and build cache behind. Not virtualisation.docker.autoPrune: its `docker system
  # prune` also deletes stopped containers, which other projects on this host keep.
  systemd.services.docker-image-prune = {
    description = "Prune unused Docker images and build cache";
    # After the runners, so a prune at boot does not delete their image before they start.
    after = [ "docker.service" ] ++ map (name: "docker-${name}.service") names;
    requires = [ "docker.service" ];
    serviceConfig.Type = "oneshot";
    path = [ config.virtualisation.docker.package ];
    script = ''
      docker image prune --all --force --filter until=72h
      docker builder prune --all --force --filter until=72h
    '';
  };
  systemd.timers.docker-image-prune = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
