# System settings extracted from Time Machine backup (2025-10-10-180724.backup)
# Only includes basic options that are widely supported in nix-darwin
{
  system.defaults = {
    # Basic NSGlobalDomain settings - most commonly supported
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = true;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = true;
      NSAutomaticSpellingCorrectionEnabled = true;
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      AppleShowAllExtensions = true;
      NSDocumentSaveNewDocumentsToCloud = false;
    };

    # Basic dock settings
    dock = {
      autohide = true;
      orientation = "bottom";
      tilesize = 50;
      minimize-to-application = false;
      show-recents = false;
      showhidden = false;
      show-process-indicators = true;
      launchanim = true;
      magnification = false;
      mineffect = "genie";
    };

    # Basic finder settings
    finder = {
      AppleShowAllFiles = false;
      ShowStatusBar = true;
      ShowPathbar = true;
      FXEnableExtensionChangeWarning = false;
      QuitMenuItem = true;
    };

    # Basic trackpad settings
    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };

    # Basic screencapture settings
    screencapture = {
      location = "~/Desktop";
      type = "png";
    };
  };
}
