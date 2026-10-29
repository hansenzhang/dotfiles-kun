#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.dotfiles
case "$(uname -s)" in
  Darwin) exec sudo darwin-rebuild switch --flake ~/.dotfiles#mac ;;
  # Builds as you and only escalates for activation, so the flake is read as its owner.
  Linux) exec nixos-rebuild switch --sudo --flake ~/.dotfiles#oci ;;
  *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac
