# Declarative app-specific defaults for tools that expose `defaults` domains.
{ ... }:
{
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
      fld = "MKRpAzlozWMNHD1kG/1TaRxRABRI7n94juZs0GdiNOhKZwMONB+6Pc0bIH+irbo=";
      "Paddle-Rectangle Pro-580977-SD" = "26e8276e930abb43e33451b8a9245a3cdeaa0d8c4d0f469cc99e35b713c4a7a3";
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
