{ pkgs, ... }:
{
  # Dual-World Font Management for macOS
  # 
  # macOS has two separate font systems that need to be configured:
  #
  # 1. Cocoa (Native macOS Framework):
  #    - Used by native macOS applications (Safari, Finder, VSCode, etc.)
  #    - Reads fonts from ~/Library/Fonts/ and system font directories
  #    - Home Manager on nix-darwin automatically symlinks fonts to:
  #      ~/Library/Fonts/HomeManager/
  #
  # 2. fontconfig (Unix/Linux Standard):
  #    - Used by Unix/CLI applications (Terminal, Emacs, CLI tools, etc.)
  #    - Reads configuration from ~/.config/fontconfig/fonts.conf
  #    - Requires explicit enablement via fonts.fontconfig.enable
  #
  # By installing fonts via home.packages and enabling fontconfig,
  # we ensure fonts work in BOTH native macOS apps and Unix applications.

  # Enable fontconfig for Unix/CLI applications
  # This generates ~/.config/fontconfig/fonts.conf
  fonts.fontconfig.enable = true;

  # Fonts installed via Home Manager are automatically:
  # 1. Symlinked to ~/Library/Fonts/HomeManager (for Cocoa apps)
  # 2. Made available to fontconfig (when enabled above)
  home.packages = with pkgs; [
    # Nerd Fonts for terminal and coding
    # Note: nerdfonts has been separated into individual packages
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack

    # System fonts for general use
    inter # Modern sans-serif, excellent for UI
    source-sans-pro # Adobe's open-source sans-serif
    source-serif-pro # Adobe's open-source serif
  ];
}
