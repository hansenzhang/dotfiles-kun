# NixOS on an Oracle Cloud Ampere A1 instance

How the `oci` host (`nixosConfigurations.oci` in `flake.nix`) gets installed, joined to Tailscale, and maintained.

## How it works

Oracle has no NixOS image, so the instance boots a stock Ubuntu image and [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) replaces it over SSH:
it kexecs into a NixOS installer in RAM, wipes and partitions the boot volume with disko (`hosts/oci/disk.nix`), and installs this flake's `oci` system.
The Mac has no Linux builder, so `--build-on remote` builds on the instance itself; almost everything comes from the binary cache.

Files:

- `hosts/oci/configuration.nix` - users, SSH, Tailscale, nix-ld, Nix GC.
- `hosts/oci/hardware.nix` - KVM guest modules, UEFI GRUB, serial console. Hand-written, so the flake evaluates without a running instance.
- `hosts/oci/disk.nix` - GPT on `/dev/sda`: BIOS-boot stub, 512M ESP, ext4 root.
- `hosts/oci/authorized_keys` - the public half of `~/.ssh/id_ed25519_oci`, the only key that can log in as `hansen`.
- `home-linux.nix` - the Linux layer on top of the shared `home.nix`.

## 1. Create the instance

OCI console, Compute, Instances, Create instance:

- **Image**: Canonical Ubuntu 26.04 Minimal aarch64. Any aarch64 Linux image works; it gets wiped.
- **Shape**: Ampere `VM.Standard.A1.Flex`, 4 OCPU and 24 GB memory (the whole Always Free allowance).
  If you get "Out of host capacity", try another availability domain or retry later.
- **Security**: leave Shielded instance / Secure Boot off. kexec and the NixOS bootloader are unsigned.
- **Networking**: a public subnet with a public IPv4 address. Keep the public IP even once Tailscale is up: it is the instance's only route out to the internet unless you add a NAT gateway, which Free Tier accounts may not be able to create.
  Then narrow the VCN security list's TCP 22 ingress rule from `0.0.0.0/0` to your home IP (`curl ifconfig.me`, as a `/32`); the install only needs SSH from your Mac.
  Step 5 removes the rule entirely.
- **SSH keys**: paste `~/.ssh/id_ed25519_oci.pub`.
- **Boot volume**: set a custom size, e.g. 100 GB. Always Free covers 200 GB of block storage in total.

Once it's running, note the public IP and check the disk name:

```sh
ssh -i ~/.ssh/id_ed25519_oci ubuntu@<public-ip> lsblk
```

The boot volume should be `sda`. If it isn't, change `device` in `hosts/oci/disk.nix` before installing - that disk gets wiped.

## 2. Install NixOS

From this repo on the Mac. The flake only sees git-tracked files, so commit (or at least `git add`) any changes first.

```sh
nix run github:nix-community/nixos-anywhere/1.13.0 -- \
  --flake .#oci \
  --build-on remote \
  --kexec https://github.com/nix-community/nixos-images/releases/download/nixos-26.05/nixos-kexec-installer-noninteractive-aarch64-linux.tar.gz \
  -i ~/.ssh/id_ed25519_oci \
  --target-host ubuntu@<public-ip>
```

It uses `sudo` on the Ubuntu side, kexecs, formats, installs, and reboots. Expect a few minutes.

Keep the `--kexec` pin. nixos-anywhere 1.13.0's default installer is a 2024 build whose kexec hung on Ubuntu 26.04's 7.0 kernel:
Ubuntu remounted its root read-only, never switched, and stopped answering SSH. The disk is only touched after the installer comes back over SSH, so a hang like that just needs a force reboot to get Ubuntu back:

```sh
nix run nixpkgs#oci-cli -- compute instance action --action RESET --instance-id <instance-ocid>
```

To see the serial console without a console connection, capture it with the CLI:

```sh
nix run nixpkgs#oci-cli -- compute console-history capture --instance-id <instance-ocid> --wait-for-state SUCCEEDED
nix run nixpkgs#oci-cli -- compute console-history get-content --instance-console-history-id <history-ocid> --length 10000000 --file console.txt
```

The host key changes with the new OS, so drop the old one and log in as yourself:

```sh
ssh-keygen -R <public-ip>
ssh -i ~/.ssh/id_ed25519_oci hansen@<public-ip>
```

## 3. Put the dotfiles in place

`home.nix` links `~/.config/nvim` and friends through `~/.dotfiles`, so those links dangle until the repo is cloned on the server.
Push your changes from the Mac first, then on the server:

```sh
git clone https://github.com/hansenzhang/dotfiles-kun.git ~/github/dotfiles-kun
cd ~/github/dotfiles-kun
./rebuild.sh
```

`rebuild.sh` creates the `~/.dotfiles` symlink and runs `nixos-rebuild switch` for `#oci`.

## 4. Join Tailscale

On the server:

```sh
sudo tailscale up --ssh
```

Open the printed URL and approve the machine. The login persists in `/var/lib/tailscale` across reboots and rebuilds.
In the Tailscale admin console, consider disabling key expiry for `oci` so it never silently drops off the tailnet.

From the Mac (the Tailscale app stays installed outside Nix there):

```sh
ssh hansen@oci
```

With `--ssh`, Tailscale handles auth by tailnet identity, no key file needed.
It only works if the tailnet policy has an `ssh` rule; without one the connection fails with "tailnet policy does not permit you to SSH to this node".
In the admin console's Access controls, add:

```json
"ssh": [
  {
    "action": "accept",
    "src":    ["autogroup:member"],
    "dst":    ["autogroup:self"],
    "users":  ["autogroup:nonroot", "root"]
  }
]
```

`accept` lets your own devices in without prompting. `check` adds a browser re-auth every 12 hours, which breaks unattended SSH such as agents and scripts.

## 5. Close the public SSH port

Once Tailscale SSH works, edit the subnet's security list in the OCI console (Networking, Virtual cloud networks, your VCN, Security):

- Remove the ingress rule for TCP 22. With no ingress rules left, the public IP accepts nothing; Tailscale still connects through outbound NAT traversal.
- Optionally add ingress UDP 41641 from `0.0.0.0/0`. It lets Tailscale peers connect directly instead of through a DERP relay; the NixOS firewall already allows it.

Only do this after `ssh hansen@oci` works. With `--ssh`, Tailscale answers port 22 on the tailnet address itself, so key-based SSH is not a fallback over the tailnet.
If Tailscale SSH breaks later, re-add the TCP 22 rule for your home IP and use `ssh -i ~/.ssh/id_ed25519_oci hansen@<public-ip>`; sshd keeps running for exactly that.

## Daily use

On the server, pull and rebuild:

```sh
cd ~/github/dotfiles-kun && git pull && ./rebuild.sh
```

Every switch is a new generation; `sudo nixos-rebuild switch --rollback` undoes the last one.

`home-linux.nix` installs Node from nixpkgs instead of nvm; `npm install -g` goes to `~/.npm-global`.
Everything else follows the stable `nixos-26.05` input, except `claude-code`, which comes from `nixos-unstable` through an overlay in `flake.nix` because stable lags it by weeks.
To pick up a newer claude-code (and stable security updates), refresh the lock, rebuild, and commit `flake.lock`:

```sh
nix flake update nixos nixpkgs-unstable && ./rebuild.sh
```
`programs.nix-ld` lets generic Linux binaries run, like uv's downloaded Pythons and npm packages that ship prebuilt executables.

`pkgs/herdr.nix` pins herdr's static release binary, since herdr isn't in nixpkgs.
To upgrade it, bump `version` and replace `hash` with the one Nix reports on the next rebuild.

## Recovery

If a rebuild breaks networking or SSH, use the OCI serial console: the instance page, Console connection, Launch Cloud Shell connection.
Reboot the instance from the console and pick an older generation in the GRUB menu.
There is no password on any account, so the console is for choosing a generation, not for logging in.

## Oracle caveats

- Always Free instances that stay idle for 7 days (low CPU, network, and memory use) can be reclaimed.
  Upgrading the tenancy to Pay As You Go stops that and still bills nothing within the Always Free limits.
- Reinstalling from scratch is the same nixos-anywhere command against a fresh Ubuntu instance.
- No nested virtualization: A1 runs on Ampere Altra (Arm v8.2), which can't expose `/dev/kvm` to guests.
  Containers work; VMs only run under slow QEMU emulation. Nested KVM on OCI needs an x86 shape (e.g. E5.Flex).
