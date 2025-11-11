# Dock configuration validated via nix-darwin `system.defaults.dock` options.
{ config, ... }:
let
  primaryUser =
    let
      raw = config.system.primaryUser or "lu";
    in
    if builtins.isString raw then raw else (raw.user or (raw.username or (raw.name or "lu")));
  users = config.users.users or { };
  userHome =
    if builtins.hasAttr primaryUser users then
      let
        cfg = builtins.getAttr primaryUser users;
      in
      cfg.home or "/Users/${primaryUser}"
    else
      "/Users/${primaryUser}";
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
