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
    nodejs_26   # stands in for nvm; global npm installs go to ~/.npm-global
    opentofu    # open-source Terraform fork; command is `tofu`
    gdal        # ogr2ogr
    tippecanoe
    claude-code # from nixos-unstable via the overlay in flake.nix
    chromium    # headless browser for chrome-devtools-axi; Google Chrome has no aarch64 Linux build
  ];
  home.sessionVariables = {
    # The Nix store is read-only, so `npm install -g` needs a user prefix.
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    # chrome-devtools-axi looks for Google Chrome by default; point it at Nix's Chromium.
    CHROME_DEVTOOLS_AXI_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";
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
