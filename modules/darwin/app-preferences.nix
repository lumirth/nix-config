# App preferences - simplified configuration
{ ... }:
{
  # Essential app preferences using nix-darwin's built-in support
  system.defaults = {
    # Configure apps through system defaults where possible
    ".GlobalPreferences" = {
      # Add any global app preferences here
    };
  };

  # Minimal activation script for apps that need special configuration
  system.activationScripts.appPreferences.text = ''
    echo "Applying essential app preferences..."

    # Alt-Tab - minimal essential settings
    defaults write com.lwouis.alt-tab-macos hideWindowlessApps -string "true"
    defaults write com.lwouis.alt-tab-macos holdShortcut -string "⌘"
    defaults write com.lwouis.alt-tab-macos theme -string "0"
    defaults write com.lwouis.alt-tab-macos SUAutomaticallyUpdate -bool false

    # Raycast - core functionality settings
    defaults write com.raycast.macos raycastGlobalHotkey -string "Command-54"
    defaults write com.raycast.macos raycastPreferredWindowMode -string "compact"
    defaults write com.raycast.macos navigationCommandStyleIdentifierKey -string "vim"



    # HyperKey - essential functionality only
    defaults write com.knollsoft.Hyperkey launchOnLogin -bool true
    defaults write com.knollsoft.Hyperkey capsLockRemapped -int 2
    defaults write com.knollsoft.Hyperkey hideMenuBarIcon -bool true

    echo "Essential app preferences applied"
    echo ""
    echo "Note: Some apps may require manual privacy permissions:"
    echo "• Raycast, Alt-Tab: Accessibility access"
    echo "• Raycast: Full Disk Access (optional)"
    echo ""
    echo "Configure these in: System Settings → Privacy & Security"
  '';
}
