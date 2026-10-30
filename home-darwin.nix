{ config, lib, pkgs, user, ... }:

# Mac-only home config, layered on top of home.nix.
let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in

{
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";
  # the font everything renders in
  home.packages = [ pkgs.nerd-fonts.hack ];
  fonts.fontconfig.enable = true;
  home.sessionVariables = {
    # openssl@3 is keg-only, so tell builds (asdf ruby/python, pkg-config) where it lives.
    # /opt/homebrew is the Apple Silicon prefix; use /usr/local on Intel.
    RUBY_CONFIGURE_OPTS = "--with-openssl-dir=/opt/homebrew/opt/openssl@3";
    PKG_CONFIG_PATH = "/opt/homebrew/opt/openssl@3/lib/pkgconfig";
    # asdf-erlang builds OTP with kerl; link crypto against openssl@3 and skip the Java bindings.
    KERL_CONFIGURE_OPTIONS = "--with-ssl=/opt/homebrew/opt/openssl@3 --without-javac";
  };

  # Global python/python3 shims in ~/.local/bin. Idempotent, so a no-op once installed.
  # uv comes from Homebrew (configuration.nix): its Python download list is baked into the
  # binary, and brew's uv tracks upstream releases much faster than the nixpkgs channel.
  home.activation.uvPython = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -x /opt/homebrew/bin/uv ]; then
      run /opt/homebrew/bin/uv python install --default 3.15
    fi
  '';

  programs.zsh = {
    initContent = ''
      # Set here, not in sessionPath, so it lands after /etc/zshrc runs `brew shellenv`
      # and these win over Homebrew's bin and macOS's LibreSSL openssl.
      export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"
      export PATH="''${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
      # uv's python/python3 shims and `uv tool install` binaries.
      export PATH="$HOME/.local/bin:$PATH"
      # nvm comes from Homebrew; node versions stay in ~/.nvm so they survive brew upgrades.
      export NVM_DIR="$HOME/.nvm"
      [ -s /opt/homebrew/opt/nvm/nvm.sh ] && . /opt/homebrew/opt/nvm/nvm.sh
      [ -s /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm ] && . /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm
      # Global npm CLIs from home.nix, after nvm so they win over copies in nvm's node versions.
      # Not NPM_CONFIG_PREFIX: nvm refuses to run with an npm prefix set.
      export PATH="$HOME/.npm-global/bin:$PATH"
    '';
    shellAliases.ll = "ls -alGh";  # BSD ls: -G is color
  };

  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
}
