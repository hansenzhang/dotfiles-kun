The same flake also defines two NixOS machines that share the Mac's shell, editor, and agent configs:

- `oci`, a headless server on an Oracle Cloud Ampere A1 instance. Install: [docs/oracle-cloud-nixos.md](docs/oracle-cloud-nixos.md).
- `desktop`, a Ryzen desktop dual-booting Windows 11, with NVIDIA drivers and a microvm.nix host. Install: [docs/desktop-nixos.md](docs/desktop-nixos.md).

## Repo tour

- `flake.nix` - the entry point.
  Wires up nixpkgs, nix-darwin, home-manager, nix-homebrew, disko, microvm.nix, and rex, and declares the `mac`, `oci`, and `desktop` machines.
- `configuration.nix` - system-level config: macOS defaults, Homebrew.
- `home.nix` - user-level config shared by every machine: shell, packages, prompt, and the symlinks described below.
- `home-darwin.nix`, `home-linux.nix` - the per-platform layers on top of `home.nix` (Homebrew paths and WezTerm on the Mac; the Homebrew CLI tools from nixpkgs on Linux).
- `hosts/oci/` - the NixOS server's system config, hardware, disk layout, and server-only home config.
- `hosts/desktop/` - the desktop's system config, hardware, microvm host, and desktop-only home config.
- `rebuild.sh` - re-applies the config after the first switch, on any machine.
  Run this every time you make a change.
- `home/` - the actual config files that get symlinked into place; the sections below explain the shared symlink model and Pi's narrower selective setup.

## Claude Code session hook

`home/.claude/settings.json` runs `gh-axi` on every session start, so agents begin with the repo's open issues and PRs in context.
`home.nix` installs `gh-axi` and the other agent CLIs into `~/.npm-global` on rebuild, and `treehouse` and `no-mistakes` into `~/.local/bin`.

## Claude session archive

Every 15 minutes, `claude-sessions-sync` copies `~/.claude` transcripts into `~/claude-sessions/<host>/`, and Syncthing shares that folder with every machine over the tailnet.
`cs QUERY` searches it: on a terminal it opens fzf with a preview of the conversation around each hit, and Enter prints the `claude --resume` command.
Agents run the same command through the `search-sessions` skill.
`cs` keeps a full-text index in `~/.cache/claude-sessions`, built on each machine from the archive, so deleting it is safe.
To add a machine:

1. Run `./rebuild.sh` on it, then `syncthing device-id` to print its ID.
2. Add it to `services.syncthing.settings.devices` in `home.nix`, with its tailnet name as the address, and to the folder's `devices` list.
3. Commit, pull on every machine, and run `./rebuild.sh` on each.


## License

This repo is licensed under MIT No Attribution.
See `LICENSE`.
