# Declarative app-specific defaults for tools that expose `defaults` domains.
{ ... }:
{
  system.defaults = {
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
  };

  # Raycast stores preferences outside macOS defaults, so keep configuring it
  # manually; only installation is declarative.
}
