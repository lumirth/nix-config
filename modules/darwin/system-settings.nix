# Declarative macOS defaults validated against nix-darwin options.
_:
{
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
  };
}
