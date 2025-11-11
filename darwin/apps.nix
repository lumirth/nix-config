# Consolidated application preferences and Dock configuration
{ config, ... }:
{
  # Dock configuration
  system.defaults.dock = {
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
      "${config.users.users.${config.system.primaryUser}.home}/Downloads"
    ];
    show-recents = false;
    show-process-indicators = true;
    tilesize = 48;
  };

  # Application-specific preferences
  system.defaults.CustomUserPreferences = {
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

  # Raycast stores preferences outside macOS defaults, so keep configuring it
  # manually; only installation is declarative.
}
