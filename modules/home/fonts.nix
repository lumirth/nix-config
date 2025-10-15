{ pkgs, ... }:
{
  # Install fonts for terminal and development
  home.packages = with pkgs; [
    nerd-fonts.meslo-lg
    nerd-fonts.fira-code
  ];

  # Enable font configuration
  fonts.fontconfig.enable = true;
}
