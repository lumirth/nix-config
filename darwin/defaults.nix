# Consolidated macOS system defaults and Touch ID configuration
{ config, ... }:

{
  # Assertions for critical configuration
  assertions = [
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

  # Touch ID for sudo (with tmux/screen support)
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    reattach = true; # CRITICAL: Enables Touch ID in tmux/screen
  };

  # macOS system defaults
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
