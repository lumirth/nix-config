{
  inputs,
  config,
  pkgs,
  ...
}:
{
  # ============================================================================
  # ASSERTIONS
  # ============================================================================

  assertions = [
    {
      assertion = !config.nix.enable;
      message = ''
        ERROR: nix.enable must be false when using Determinate Nix.
        Determinate manages the Nix daemon directly.
        Remove 'nix.enable = true;' from your configuration.
      '';
    }
    {
      assertion = config.security.pam.services.sudo_local.enable;
      message = ''
        ERROR: Touch ID sudo must be enabled.
        This configuration requires Touch ID authentication for sudo.
        The security.pam.services.sudo_local.enable option should be true.
      '';
    }
    {
      assertion =
        config.security.pam.services.sudo_local.enable -> config.security.pam.services.sudo_local.reattach;
      message = ''
        ERROR: Touch ID sudo requires reattach = true for tmux/screen support.
        Add 'security.pam.services.sudo_local.reattach = true;' to your configuration.
        This enables Touch ID authentication within terminal multiplexers.
      '';
    }
  ];

  # ============================================================================
  # DETERMINATE NIX CONFIGURATION
  # ============================================================================

  # Determinate Nix manages the Nix daemon configuration
  nix.enable = false;

  determinate-nix.customSettings =
    let
      inherit (pkgs) lib;
    in
    {
      "experimental-features" = "nix-command flakes";
      "trusted-users" = "root lu";

      # Binary caches: NixOS official + nix-community + personal cache
      # Personal cache (lu-nix-config.cachix.org) speeds up builds by providing
      # pre-built custom packages (overlays) and reduces bootstrap time on new machines.
      "trusted-substituters" = lib.concatStringsSep " " [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://lu-nix-config.cachix.org"
      ];

      "trusted-public-keys" = lib.concatStringsSep " " [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        # TODO: Add Cachix public key after cache creation
        # To create and configure the cache:
        # 1. Create a free cache at https://app.cachix.org (name: lu-nix-config)
        # 2. Install cachix CLI (already in modules/home/packages.nix)
        # 3. Authenticate: cachix authtoken <YOUR_TOKEN>
        # 4. Push custom packages: cachix push lu-nix-config $(nix build .#claude-code-acp --print-out-paths)
        # 5. Add the public key here: "lu-nix-config.cachix.org-1:<PUBLIC_KEY>"
        # 6. Rebuild: sudo darwin-rebuild switch --flake .#lu-mbp
      ];

      "max-jobs" = "auto";
      "cores" = "0";
    };

  # ============================================================================
  # SYSTEM CONFIGURATION
  # ============================================================================

  system.stateVersion = 6;
  system.primaryUser = "lu";

  nixpkgs.hostPlatform = "aarch64-darwin";
  networking.hostName = "lu-mbp";

  # Ensure preferred shell is installed system-wide
  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];

  users.users.lu = {
    name = "lu";
    home = "/Users/lu";
    shell = pkgs.zsh;
  };

  # ============================================================================
  # TOUCH ID CONFIGURATION
  # ============================================================================

  # Touch ID for sudo (with tmux/screen support)
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    reattach = true; # CRITICAL: Enables Touch ID in tmux/screen
  };

  # ============================================================================
  # MACOS SYSTEM DEFAULTS
  # ============================================================================

  system.defaults = {
    NSGlobalDomain = {
      AppleShowAllFiles = true;
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
    };

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      FXDefaultSearchScope = "SCcf";
      FXPreferredViewStyle = "Nlsv";
      ShowPathbar = true;
      ShowStatusBar = true;
      _FXSortFoldersFirst = true;
    };

    screencapture = {
      disable-shadow = true;
      location = "~/Pictures/Screenshots";
      show-thumbnail = false;
      type = "png";
    };

    # Dock configuration
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.15;
      largesize = 64;
      magnification = true;
      mru-spaces = false;
      persistent-apps = [
        { app = "/Applications/Raycast.app"; }
        { app = "/Applications/Arc.app"; }
        { app = "/Applications/Zed.app"; }
        { app = "/Applications/iTerm.app"; }
        { app = "/Applications/Obsidian.app"; }
      ];
      persistent-others = [
        {
          folder = {
            path = "${config.users.users.${config.system.primaryUser}.home}/Downloads";
            arrangement = "date-added";
          };
        }
      ];
      show-recents = false;
      show-process-indicators = true;
      tilesize = 48;
    };

    # Application-specific preferences
    CustomUserPreferences = {
      "com.lwouis.alt-tab-macos" = {
        hideWindowlessApps = true;
        holdShortcut = "⌘";
        theme = "0";
        SUAutomaticallyUpdate = false;
      };

      "com.knollsoft.Hyperkey" = {
        launchOnLogin = true;
        capsLockRemapped = 2;
        hideMenuBarIcon = true;
      };

      "com.knollsoft.Hookshot" = {
        launchOnLogin = true;
        allowAnyShortcut = true;
        hookshotStatusIcon = 1;
        quickActions = 2;
        internalTilingNotified = true;
        gestures = "[2,{\"trail\":1,\"flags\":0},0,{\"trail\":3,\"flags\":0},11,{\"trail\":1,\"flags\":0},10,{\"trail\":2,\"flags\":0},1,{\"trail\":4,\"flags\":0},33,{\"trail\":0,\"flags\":1966080},32,{\"trail\":0,\"flags\":1835008}]";
        installVersion = "203";
        lastVersion = "203";
        SUEnableAutomaticChecks = true;
        SUHasLaunchedBefore = true;
      };
    };
  };

  # Raycast stores preferences outside macOS defaults, so keep configuring it
  # manually; only installation is declarative.

  # ============================================================================
  # NIX-HOMEBREW CONFIGURATION
  # ============================================================================

  # nix-homebrew configuration
  nix-homebrew = {
    enable = true;
    user = "lu";
    autoMigrate = true;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
    mutableTaps = false;
  };

  # ============================================================================
  # HOMEBREW CONFIGURATION
  # ============================================================================

  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";

    casks = [
      "zed"
      "rectangle-pro"
      "raycast"
      "arc"
      "anki"
      "keka"
      "iterm2"
      "shottr"
      "zotero"
      "alienator88-sentinel"
      "pearcleaner"
      "oversight"
      "lulu"
      "knockknock"
      "blockblock"
      "calibre"
      "hyperkey"
      "orcaslicer"
      "alt-tab"
      "adobe-creative-cloud"
      "iina"
      "linearmouse"
      "monitorcontrol"
      "keepingyouawake"
      "handbrake-app"
      "bambu-studio"
      "ollama-app"
      "lm-studio"
      "cursor"
      "netnewswire"
      "jetbrains-toolbox"
      "android-studio"
      "obsidian"
      "orbstack"
      "thebrowsercompany-dia"
      "macfuse"
      "prismlauncher"
      "zen"
      "google-chrome"
    ];

    brews = [ ];

    masApps = {
      "CotEditor" = 1024640650;
      "Microsoft Word" = 462054704;
      "Microsoft Excel" = 462058435;
      "Microsoft Powerpoint" = 462062816;
      # "Barbee" = 1548711022;
      "Dropover" = 1355679052;
      "Hand Mirror" = 1502839586;
      "Folder Quick Look" = 6753110395;
      "Infuse" = 1136220934;
      "CleanMyKeyboard" = 6468120888;
      "PairVPN" = 1347012179;
      "Testflight" = 899247664;
      "Xcode" = 497799835;
      "PastePal" = 1503446680;
      "Reeder" = 6475002485;
      "News Explorer" = 1032670789;
      "GoodLinks" = 1474335294;
      "Ulysses" = 1225570693;
    };

    taps = builtins.attrNames config.nix-homebrew.taps;
  };
}
