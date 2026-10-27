{ config, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    lazygit
    neovim
    # the font everything renders in
    nerd-fonts.hack
  ];
  fonts.fontconfig.enable = true;
  home.sessionVariables = {
    EDITOR = "nvim";
    # openssl@3 is keg-only, so tell builds (asdf ruby/python, pkg-config) where it lives.
    # /opt/homebrew is the Apple Silicon prefix; use /usr/local on Intel.
    RUBY_CONFIGURE_OPTS = "--with-openssl-dir=/opt/homebrew/opt/openssl@3";
    PKG_CONFIG_PATH = "/opt/homebrew/opt/openssl@3/lib/pkgconfig";
    # asdf-erlang builds OTP with kerl; link crypto against openssl@3 and skip the Java bindings.
    KERL_CONFIGURE_OPTIONS = "--with-ssl=/opt/homebrew/opt/openssl@3 --without-javac";
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    initContent = ''
      bindkey '^f' autosuggest-accept
      # Set here, not in sessionPath, so it lands after /etc/zshrc runs `brew shellenv`
      # and these win over Homebrew's bin and macOS's LibreSSL openssl.
      export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"
      export PATH="''${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
      # nvm comes from Homebrew; node versions stay in ~/.nvm so they survive brew upgrades.
      export NVM_DIR="$HOME/.nvm"
      [ -s /opt/homebrew/opt/nvm/nvm.sh ] && . /opt/homebrew/opt/nvm/nvm.sh
      [ -s /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm ] && . /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm
    '';
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";

  # Keep Pi's credential and runtime state local by linking only authored files and directories.
  home.file.".pi/agent/themes".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/themes";
  home.file.".pi/agent/extensions".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/extensions";
  home.file.".pi/agent/models.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/models.json";
  home.file.".pi/agent/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/settings.json";

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
