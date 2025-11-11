{
  inputs,
  config,
  pkgs,
  ...
}:
{
  # Assertions
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
      assertion = pkgs ? claude-code-acp || builtins.pathExists ./pkgs/claude-code-acp/default.nix;
      message = ''
        ERROR: Custom package claude-code-acp is not available.
        The package should be defined in flake.nix as a flake output:
          packages.aarch64-darwin.claude-code-acp = pkgs.callPackage ./pkgs/claude-code-acp { };

        And the package definition should exist at:
          ./pkgs/claude-code-acp/default.nix

        Verify that:
        1. The package is defined in flake.nix perSystem.packages
        2. The package definition file exists
        3. The flake has been evaluated successfully
      '';
    }
  ];

  # Import modular components
  imports = [
    ./darwin/defaults.nix
    ./darwin/apps.nix
  ];

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

  system.stateVersion = 6;
  system.primaryUser = "lu";

  nixpkgs.hostPlatform = "aarch64-darwin";

  # Ensure preferred shell is installed system-wide
  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];

  users.users.lu = {
    name = "lu";
    home = "/Users/lu";
    shell = pkgs.zsh;
  };

  system.activationScripts.validateDeterminateNix = ''
    if ! command -v nix >/dev/null 2>&1; then
      echo "ERROR: Determinate Nix is not installed (nix not found)" >&2
      exit 1
    fi

    if [ ! -r /etc/nix/nix.custom.conf ]; then
      echo "WARNING: /etc/nix/nix.custom.conf missing or unreadable" >&2
    fi

    if command -v determinate-nixd >/dev/null 2>&1; then
      determinate-nixd --version
    else
      echo "WARNING: determinate-nixd daemon not found" >&2
    fi
  '';

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

  # Homebrew configuration
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";

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
