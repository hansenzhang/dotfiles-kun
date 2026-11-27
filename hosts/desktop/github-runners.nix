# desktop's runner, for lucky-contour's jobs that build linux/amd64 images (dry-run, deploy), which crash
# under qemu on oci. Workflows reach it with the X64 label. No prune timer: the captain keeps lc images in
# this Docker. The runner containers are in ../github-runners.nix.
{
  imports = [
    (import ../github-runners.nix { host = "desktop"; names = [ "runner-1" ]; labels = "desktop"; memory = "6g"; cpus = 6; })
  ];
}
