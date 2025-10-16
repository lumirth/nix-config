{ pkgs, ... }:
{
  imports = [
    ./modules/darwin/system-settings.nix
    ./modules/darwin/app-preferences.nix
    ./modules/darwin/dock.nix
    ./modules/darwin/touchid-sudo.nix
  ];
  # Required for Determinate Nix
  nix.enable = false;

  # System settings
  system.stateVersion = 6;
  system.primaryUser = "lu";
  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.trusted-users = [
    "root"
    "lu"
  ];

  # Enable fish at the system level
  programs.fish.enable = true;

  # Define the user (required for home-manager)
  users.users.lu = {
    name = "lu";
    home = "/Users/lu";
    shell = pkgs.fish;
  };

  # Add fish to /etc/shells
  environment.shells = [ pkgs.fish ];

  # Activation script to actually change the user's shell
  # Note: nix-darwin's users.users.*.shell doesn't change existing users
  system.activationScripts.extraActivation.text = ''
    echo "Setting shell for user lu to fish..."

    FISH_PATH="/run/current-system/sw/bin/fish"
    CURRENT_SHELL=$(dscl . -read /Users/lu UserShell 2>/dev/null | awk '{print $2}')

    if [ "$CURRENT_SHELL" != "$FISH_PATH" ]; then
      echo "Current shell: $CURRENT_SHELL"
      echo "Changing to: $FISH_PATH"
      dscl . -create /Users/lu UserShell "$FISH_PATH"
      echo "Shell changed successfully. You may need to restart your terminal."
    else
      echo "Shell is already set to fish"
    fi
  '';

  # Declarative Homebrew
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
    ];

    brews = [ ];

    masApps = {
      "CotEditor" = 1024640650;
      "Microsoft Word" = 462054704;
      "Microsoft Excel" = 462058435;
      "Microsoft Powerpoint" = 462062816;
      "Barbee" = 1548711022;
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
      "Anybox" = 1593408455;
    };
  };
}
