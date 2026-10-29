# disko layout. nixos-anywhere wipes the boot volume and partitions it like this at install time.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";  # the OCI boot volume
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02";  # GRUB BIOS boot; unused under UEFI but keeps GRUB's install happy
        };
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
