{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.fish = {
    enable = true;
    shellInit = ''
      set -gx EDITOR zed
    '';
  };
}
