{ config, ... }:

# Ryzen 5 5600X3D, GTX 1080 Ti, 1 TB Intel NVMe shared with Windows 11, 2 TB data HDD.
# Hand-written like oci's so the flake evaluates before the install. Existing partitions are
# matched by GPT partition GUID (what Windows' Get-Partition shows), so nothing on the Windows
# side needs relabelling.
let
  partuuid = id: "/dev/disk/by-partuuid/${id}";
  # Shared with Windows. ntfs3 is the in-kernel driver; nofail + automount keep a dirty or
  # hibernated volume from blocking boot. windows_names refuses names Windows can't open.
  ntfs = device: {
    inherit device;
    fsType = "ntfs3";
    options = [ "uid=1000" "gid=100" "umask=022" "windows_names" "nofail" "x-systemd.automount" ];
  };
in
{
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-amd" ];  # microVMs, see microvm.nix

  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;  # Intel AC 9260 Wi-Fi/Bluetooth

  # The 512M ESP Windows already uses; systemd-boot finds Windows Boot Manager there on its own.
  fileSystems."/boot" = {
    device = partuuid "d76f76d6-9339-11f0-8d57-7085c2adc0c2";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };
  # Made at install time in the free space between E: and C: (docs/desktop-nixos.md).
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/mnt/games" = ntfs (partuuid "d76f76d7-9339-11f0-8d57-7085c2adc0c2");  # E:, NVMe
  fileSystems."/mnt/data" = ntfs (partuuid "41f316e8-33f1-4baa-acc5-905f3d769a43");   # D:, HDD

  # No swap partition; compressed swap in RAM is plenty with 32 GB.
  zramSwap.enable = true;

  # Pascal isn't supported by the open kernel modules, and 580 is the last driver branch for it.
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # Steam/Proton
  };
  hardware.nvidia = {
    open = false;
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
  };

  nixpkgs.hostPlatform = "x86_64-linux";
}
