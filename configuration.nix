{ user, ... }:

let
  trackpadSwipes = {
    TrackpadThreeFingerHorizSwipeGesture = 1;  # swipe between pages
    TrackpadFourFingerHorizSwipeGesture = 2;   # swipe between full-screen apps (workspaces)
  };
in

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;          # fast key repeat
      InitialKeyRepeat = 15;  # short delay before repeat
      _HIHideMenuBar = true;  # auto-hide the menu bar
      AppleShowAllExtensions = true;
    };
    dock.autohide = true;
    finder.FXPreferredViewStyle = "Nlsv";  # list view by default
    finder.CreateDesktop = false;          # clean desktop
    trackpad.Clicking = true;              # tap to click
    # 4 fingers swap workspaces, 3 fingers go back/forward. nix-darwin has no options for these;
    # both domains because built-in and Bluetooth trackpads read different ones.
    CustomUserPreferences = {
      "com.apple.AppleMultitouchTrackpad" = trackpadSwipes;
      "com.apple.driver.AppleBluetoothMultitouch.trackpad" = trackpadSwipes;
    };
  };
  # ISO section/plus-minus key (0x64) -> backtick/tilde (0x35). hidutil mappings don't survive
  # a reboot, so re-apply at login.
  launchd.user.agents.remap-section-key.serviceConfig = {
    ProgramArguments = [
      "/usr/bin/hidutil" "property" "--set"
      ''{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000064,"HIDKeyboardModifierMappingDst":0x700000035}]}''
    ];
    RunAtLoad = true;
  };
  nix-homebrew = {
    enable = true;
    autoMigrate = true;
    inherit user;
  };
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";  # remove anything not listed here
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];
    brews = [
      "herdr"
      "tmux"
      "gh"        # GitHub CLI
      "asdf"      # runtime version manager; shims are wired up in home.nix
      "openssl@3" # keg-only; home.nix points PATH and build tools at it
      "opentofu"  # open-source Terraform fork; command is `tofu`
      "autoconf"  # asdf-erlang needs it to build Erlang/OTP
      "gdal"      # ogr2ogr, for refactored-dollop's tile pipeline
      "tippecanoe"
      "nvm"       # Node version manager; loaded in home.nix
      "uv"        # Python; home.nix installs the default interpreter with it
    ];
    casks = [
      "wezterm"
      "claude-code"
    ];
  };
}
