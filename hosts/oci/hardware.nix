{ modulesPath, ... }:

# OCI A1 instances are KVM guests that boot UEFI from a paravirtualized SCSI boot volume.
# Written by hand rather than generated, so the flake evaluates before the instance exists.
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "virtio_pci" "virtio_scsi" "usbhid" ];

  # GRUB in the removable-media path (EFI/BOOT/BOOTAA64.EFI) boots without NVRAM entries,
  # which OCI's firmware doesn't reliably keep. disko fills in the GRUB devices.
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  # ttyAMA0 last makes it the primary console, so boot logs and login reach the OCI
  # serial console. The UEFI firmware already mirrors the GRUB menu there.
  boot.kernelParams = [ "console=tty1" "console=ttyAMA0,115200" ];

  nixpkgs.hostPlatform = "aarch64-linux";
}
