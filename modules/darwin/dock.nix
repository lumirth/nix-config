# Dock configuration validated via nix-darwin `system.defaults.dock` options.
{ ... }:
{
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
      "/Users/lu/Downloads"
    ];
    show-recents = false;
    show-process-indicators = true;
    tilesize = 48;
  };
}
