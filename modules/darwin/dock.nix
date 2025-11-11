# Dock configuration validated via nix-darwin `system.defaults.dock` options.
{ config, ... }:
let
  primaryUserValue = config.system.primaryUser or "lu";
  primaryUserName =
    if builtins.isAttrs primaryUserValue then
      primaryUserValue.user or (primaryUserValue.username or (primaryUserValue.name or "lu"))
    else
      primaryUserValue;
  userHome =
    let
      users = config.users.users or { };
    in
    if builtins.isString primaryUserName && builtins.hasAttr primaryUserName users then
      let
        cfg = builtins.getAttr primaryUserName users;
      in
        cfg.home or "/Users/${primaryUserName}"
    else
      "/Users/${primaryUserName}";
in
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
      "${userHome}/Downloads"
    ];
    show-recents = false;
    show-process-indicators = true;
    tilesize = 48;
  };
}
