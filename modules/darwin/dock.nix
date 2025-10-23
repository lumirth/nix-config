# Dock configuration using nix-darwin's built-in options
{ ... }:
{
  system.defaults.dock = {
    # Basic dock behavior (inherited from system-settings.nix)
    # Additional dock-specific settings
    persistent-apps = [
      # System Apps
      "/System/Applications/Apps.app"
      # Third-party apps (paths will be resolved when apps are installed)
      "/Applications/Arc.app"
      "/System/Applications/Notes.app"
      "/System/Applications/Reminders.app"
      "/System/Applications/Messages.app"
      "/Applications/Zed.app"
      "/Applications/OrcaSlicer.app"
    ];

    persistent-others = [
      "/Users/lu/Downloads"
    ];
  };

  # Simple activation script to handle missing apps gracefully
  system.activationScripts.dockApps.text = ''
    echo "Configuring dock applications..."

    # Remove non-existent apps from dock to prevent errors
    DOCK_PLIST="$HOME/Library/Preferences/com.apple.dock.plist"

    # Only restart dock if configuration changed
    if ! defaults read com.apple.dock persistent-apps 2>/dev/null | grep -q "Zed\|Arc\|OrcaSlicer"; then
      echo "Dock configuration updated - restarting Dock"
      killall Dock 2>/dev/null || true
    else
      echo "Dock already configured"
    fi
  '';
}
