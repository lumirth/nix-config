{ pkgs, config, ... }:

{
  # Rectangle Pro license file deployment
  home.file = {
    # Main license file (product data)
    "Library/Application Support/Rectangle Pro/580977.padl" = {
      source = ../../../data/rectangle-pro/580977.padl;
      executable = false;
      force = true;
    };

    # Secondary license file
    "Library/Application Support/Rectangle Pro/580977.spadl" = {
      source = ../../../data/rectangle-pro/580977.spadl;
      executable = false;
      force = true;
    };
  };

  # Rectangle Pro preferences with license key
  home.activation.rectangleProLicense = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    echo "Setting up Rectangle Pro license..."

    # Ensure preferences directory exists
    mkdir -p "$HOME/Library/Preferences"

    # Apply Rectangle Pro preferences with license information
    /usr/bin/defaults write com.knollsoft.Hookshot launchOnLogin -bool true
    /usr/bin/defaults write com.knollsoft.Hookshot allowAnyShortcut -bool true
    /usr/bin/defaults write com.knollsoft.Hookshot hookshotStatusIcon -int 1
    /usr/bin/defaults write com.knollsoft.Hookshot quickActions -int 2
    /usr/bin/defaults write com.knollsoft.Hookshot internalTilingNotified -bool true

    # License-specific settings
    /usr/bin/defaults write com.knollsoft.Hookshot fld -string "MKRpAzlozWMNHD1kG/1TaRxRABRI7n94juZs0GdiNOhKZwMONB+6Pc0bIH+irbo="
    /usr/bin/defaults write com.knollsoft.Hookshot "Paddle-Rectangle Pro-580977-SD" -string "26e8276e930abb43e33451b8a9245a3cdeaa0d8c4d0f469cc99e35b713c4a7a3"

    # Gesture configuration from original backup
    /usr/bin/defaults write com.knollsoft.Hookshot gestures -string "[2,{\"trail\":1,\"flags\":0},0,{\"trail\":3,\"flags\":0},11,{\"trail\":1,\"flags\":0},10,{\"trail\":2,\"flags\":0},1,{\"trail\":4,\"flags\":0},33,{\"trail\":0,\"flags\":1966080},32,{\"trail\":0,\"flags\":1835008}]"

    # Version tracking
    /usr/bin/defaults write com.knollsoft.Hookshot installVersion -string "203"
    /usr/bin/defaults write com.knollsoft.Hookshot lastVersion -string "203"

    # Auto-update preferences
    /usr/bin/defaults write com.knollsoft.Hookshot SUEnableAutomaticChecks -bool true
    /usr/bin/defaults write com.knollsoft.Hookshot SUHasLaunchedBefore -bool true

    echo "Rectangle Pro license configuration complete"
    echo "Note: Rectangle Pro requires Accessibility permissions in System Settings → Privacy & Security"
  '';
}
