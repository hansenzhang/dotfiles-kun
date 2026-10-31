{ config, lib, pkgs, user, inputs, ... }:

# Shared by every machine. Platform-only bits live in home-darwin.nix and home-linux.nix.
let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";

  # Agent skills by name. Mine live in home/skills and link out of the store so edits apply live;
  # upstream ones come pinned from flake inputs.
  skills = {
    unslop = "${dotfiles}/home/skills/unslop";
    writing-for-agents = "${inputs.mattpocock-skills}/skills/productivity/writing-for-agents";
  };
in

{
  home.username = user;
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    lazygit
    neovim
  ];
  home.sessionVariables = {
    EDITOR = "nvim";
    # Projects get uv-downloaded Pythons, never a system or package-manager one.
    UV_PYTHON_PREFERENCE = "only-managed";
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    initContent = ''
      bindkey '^f' autosuggest-accept
    '';
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      g = "git";  # g co, g ol, g st
      v = "nvim";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
    };
  };

  # Agent CLIs that aren't in nixpkgs, in ~/.npm-global on both platforms. Uses Nix's Node so the
  # Mac's nvm version doesn't matter. Installs only the missing ones; upgrade with
  # `npm update -g --prefix ~/.npm-global`.
  # `setup hooks` is idempotent and adds the SessionStart hooks for Claude, Codex, OpenCode and
  # Copilot. Claude's land in the linked settings.json, which already carries them.
  home.activation.npmGlobals = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${pkgs.nodejs_26}/bin:$HOME/.npm-global/bin:$PATH"
    missing=""
    for p in gh-axi lavish-axi tasks-axi quota-axi chrome-devtools-axi; do
      [ -d "$HOME/.npm-global/lib/node_modules/$p" ] || missing="$missing $p"
    done
    if [ -n "$missing" ]; then
      run npm install -g --prefix "$HOME/.npm-global" $missing
    fi
    for p in gh-axi lavish-axi chrome-devtools-axi; do
      run $p setup hooks > /dev/null
    done
  '';

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
      format = "$hostname$directory$git_branch$git_status$cmd_duration$line_break$character";
      # Only shown over SSH (starship's default ssh_only), so a remote shell never passes for the Mac.
      hostname.format = "[$hostname]($style) ";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
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

  # Claude gets each skill linked into ~/.claude/skills, which also holds its own synced skills.
  # Codex and Pi read ~/.agents/skills, one link to a folder holding them all.
  imports = [{
    home.file = lib.mapAttrs' (name: path: lib.nameValuePair ".claude/skills/${name}" {
      source = config.lib.file.mkOutOfStoreSymlink path;
    }) skills;
  }];
  home.file.".agents/skills".source = pkgs.linkFarm "agent-skills" skills;

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
