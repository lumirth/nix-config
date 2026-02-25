{ config, ... }:
{
  homebrew = {
    enable = true;
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
    onActivation.cleanup = "uninstall";

    casks = [
      "zed"
      "rectangle-pro"
      "raycast"
      "arc"
      "anki"
      "keka"
      "iterm2"
      "shottr"
      "tailscale-app"
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
      "claude"
      "claude-code"
      "netnewswire"
      "jetbrains-toolbox"
      "android-studio"
      "obsidian"
      "orbstack"
      "thebrowsercompany-dia"
      "macfuse"
      "prismlauncher"
      "zen"
      "google-chrome"
      "discord"
      "antigravity"
      "raspberry-pi-imager"
      "wispr-flow"
      "telegram"
    ];

    brews = [
      "supabase"
      "deno"
      "libpq"
      "pnpm"
    ];

    masApps = {
      "CotEditor" = 1024640650;
      "Microsoft Word" = 462054704;
      "Microsoft Excel" = 462058435;
      "Microsoft Powerpoint" = 462062816;
      # "Barbee" = 1548711022;
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
      "GoodLinks" = 1474335294;
      "Ulysses" = 1225570693;
    };

    taps = builtins.attrNames config.nix-homebrew.taps;
  };
}
