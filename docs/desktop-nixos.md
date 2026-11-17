# NixOS on the desktop, dual-booting Windows 11

How the `desktop` host (`nixosConfigurations.desktop` in `flake.nix`) gets installed next to Windows.

## Layout

One 1 TB NVMe, shared with Windows; nothing on it is wiped.

| Partition | Size | Use |
|---|---|---|
| p1 ESP | 512M | Shared: Windows Boot Manager + systemd-boot (5 generations max) |
| p2 E: | 552G NTFS | Windows games (Genshin). Mounted at `/mnt/games` |
| new, label `nixos` | ~249G ext4 | NixOS root: Nix store, Docker, Steam/Proton library, microVMs |
| p3 MSR, p4 C:, p5 Recovery | | Windows 11 |

D: (2 TB HDD, NTFS) is mounted at `/mnt/data`.
Keep the Nix store, Docker, Steam libraries and VM images off the NTFS drives.

Files:

- `hosts/desktop/configuration.nix` - boot loader, Plasma, NVIDIA, Steam, users, Tailscale.
- `hosts/desktop/hardware.nix` - modules, filesystems (by GPT partition GUID), NVIDIA 580 legacy driver for the 1080 Ti.
- `hosts/desktop/microvm.nix` - microvm.nix host: `microvm` bridge on 10.0.0.1/24, NAT, VM state in `/var/lib/microvms`.

## 1. Prepare Windows (admin PowerShell)

```powershell
bcdedit /export C:\bcd-backup
# Stale Windows 10 entries pointing at E:
bcdedit /delete {3c476ae3-9343-11f0-8d57-7085c2adc0c2}
bcdedit /delete {3c476ae2-9343-11f0-8d57-7085c2adc0c2}
bcdedit /delete {3c50f478-9343-11f0-8d57-7085c2adc0c2}
# A hibernated Windows leaves the NTFS drives read-only for Linux; also frees 12.8G on C:
powercfg /h off
manage-bde -status
```

If `manage-bde` shows C: encrypted (BitLocker / Device Encryption), save the recovery key from
https://account.microsoft.com/devices/recoverykey before touching firmware settings.

## 2. Firmware

- Turn Secure Boot off (systemd-boot is unsigned). Windows 11 keeps booting without it.
- Boot the NixOS 26.05 graphical ISO from USB.

## 3. Partition and install (live USB)

```sh
lsblk -f   # NVMe is nvme0n1; p1 is the 545M vfat ESP. The HDD is sda.
# New partition filling the largest free block (the gap between E: and C:)
sudo sgdisk -n 0:0:0 -t 0:8300 -c 0:nixos /dev/nvme0n1
lsblk /dev/nvme0n1   # the new ~249G partition is nvme0n1p6
sudo mkfs.ext4 -L nixos /dev/nvme0n1p6

sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount -o umask=0077 /dev/nvme0n1p1 /mnt/boot   # do NOT format this

# The repo lives on D: (D:\dotfiles-kun, branch desktop-host), so no push is needed
sudo mkdir -p /mnt/data
sudo mount -t ntfs3 -o ro,uid=$(id -u) /dev/disk/by-partuuid/41f316e8-33f1-4baa-acc5-905f3d769a43 /mnt/data
nix-shell -p git --run 'git clone -b desktop-host /mnt/data/dotfiles-kun /tmp/dotfiles'
sudo umount /mnt/data
sudo nixos-install --flake /tmp/dotfiles#desktop --no-root-passwd
sudo nixos-enter --root /mnt -c 'passwd hansen'
```

Reboot. The systemd-boot menu should list NixOS and Windows Boot Manager.

## 4. First boot

NixOS boots to a text console. Log in, then `gui` starts the Plasma login screen and `gui off` stops it.

```sh
git clone -b desktop-host /mnt/data/dotfiles-kun ~/dotfiles
cd ~/dotfiles && ./rebuild.sh   # links ~/.dotfiles, switches to #desktop by hostname
git add flake.lock && git commit -m "lock microvm"   # the first build adds the new input to the lock
git push origin desktop-host   # optional: send the lock back to D:\dotfiles-kun (origin is D: here)
sudo tailscale up
```

Then boot Windows once and check the clock is right (`time.hardwareClockInLocalTime`).

## Recovery

- Windows won't boot from the menu: pick "Windows Boot Manager" in the firmware boot menu, or restore with `bcdedit /import C:\bcd-backup`.
- NixOS won't boot: pick an older generation in systemd-boot, or from the live USB mount as in step 3 and `nixos-enter --root /mnt`.
- `/mnt/games` or `/mnt/data` read-only: Windows hibernated or Fast Startup came back on. Boot Windows, shut down fully (`shutdown /s /t 0`).
