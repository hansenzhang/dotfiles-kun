{ ... }:

# Host side of microvm.nix (Firecracker, cloud-hypervisor, qemu). Guests go under `microvm.vms`.
# Each guest's tap interface is named vm-* and joins the `microvm` bridge; the host NATs the
# bridge out of whichever uplink NetworkManager has up (Ethernet or Wi-Fi).
# Give guests static addresses in 10.0.0.0/24 with 10.0.0.1 as gateway.
{
  # VM images and volumes live on the ext4 root, never on the NTFS drives.
  microvm.stateDir = "/var/lib/microvms";

  systemd.network = {
    enable = true;
    # networkd only manages the bridge, so don't hold up boot waiting for it to be "online".
    wait-online.enable = false;
    netdevs."10-microvm".netdevConfig = {
      Kind = "bridge";
      Name = "microvm";
    };
    networks."10-microvm" = {
      matchConfig.Name = "microvm";
      addresses = [ { Address = "10.0.0.1/24"; } ];
      networkConfig.ConfigureWithoutCarrier = true;
    };
    networks."11-microvm-taps" = {
      matchConfig.Name = "vm-*";
      networkConfig.Bridge = "microvm";
    };
  };
  # NetworkManager runs the real uplinks; keep it off the bridge and taps.
  networking.networkmanager.unmanaged = [ "interface-name:microvm" "interface-name:vm-*" ];

  networking.nat = {
    enable = true;
    internalInterfaces = [ "microvm" ];
  };
  networking.firewall.trustedInterfaces = [ "microvm" ];
}
