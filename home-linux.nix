{ lib, pkgs, user, ... }:

# Linux-only home config, layered on top of home.nix.
# Covers the Homebrew CLI tools from configuration.nix that make sense on a headless server.
{
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "26.05";
  home.packages = with pkgs; [
    (callPackage ./pkgs/herdr.nix { })
    tmux
    gh          # GitHub CLI
    uv          # Python; the activation below installs the default interpreter with it
    nodejs_24   # stands in for nvm; global npm installs go to ~/.npm-global
    opentofu    # open-source Terraform fork; command is `tofu`
    gdal        # ogr2ogr
    tippecanoe
    claude-code
  ];
  home.sessionVariables = {
    # The Nix store is read-only, so `npm install -g` needs a user prefix.
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };

  # Global python/python3 shims in ~/.local/bin. Idempotent, so a no-op once installed.
  # The downloaded Pythons are generic Linux binaries; programs.nix-ld on the host runs them.
  home.activation.uvPython = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.uv}/bin/uv python install --default 3.15
  '';

  programs.zsh = {
    initContent = ''
      # uv's python/python3 shims and `uv tool install` binaries, then global npm installs.
      export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"
    '';
    shellAliases.ll = "ls -alh --color=auto";  # GNU ls: -G would hide the group column
  };
}
