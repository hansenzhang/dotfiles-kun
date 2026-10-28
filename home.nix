{ config, lib, pkgs, user, ... }:

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
    # Projects get uv-downloaded Pythons, never Homebrew's (a gdal dependency) or macOS's 3.9.
    UV_PYTHON_PREFERENCE = "only-managed";
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
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    initContent = ''
      bindkey '^f' autosuggest-accept
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
    '';
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      g = "git";  # g co, g ol, g st
      ll = "ls -alGh";
      v = "nvim";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
    };
  };

  # Ctrl-R history, Ctrl-T file path, Alt-C cd. fd makes the pickers skip .git and gitignored files.
  programs.fzf = {
    enable = true;
    defaultCommand = "fd --type f --hidden --exclude .git";
    fileWidgetCommand = "fd --type f --hidden --exclude .git";
    changeDirWidgetCommand = "fd --type d --hidden --exclude .git";
  };

  # Replaces the hand-written ~/.gitconfig; aliases are `git <name>` subcommands.
  programs.git = {
    enable = true;
    settings = {
      user.name = "hansenzhang";
      user.email = "hansen@hansenzhang.com";
      pull.ff = "only";
      push.autoSetupRemote = true; 
      alias = {
        co = "checkout";
        st = "status";
        ol = "log --all --graph --date=format:'%Y-%m-%d %H:%M' --format='%C(auto)%h %C(blue)%ad %C(green)(%ar)%C(auto)%d %s %C(dim)<%an>'";
      };
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
