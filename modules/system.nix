{ pkgs, ... }:
{
  imports = [
    ./darwin/system-settings.nix
    ./darwin/app-preferences.nix
    ./darwin/dock.nix
    ./darwin/touchid-sudo.nix
  ];

  # Determinate Nix manages the Nix daemon configuration
  nix.enable = false;
  determinate-nix.customSettings = {
    experimental-features = "nix-command flakes";
    trusted-users = "root lu";
    trusted-substituters = "https://cache.nixos.org https://nix-community.cachix.org";
    trusted-public-keys = ''
      cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
      nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
    '';
    max-jobs = "auto";
    cores = "0";
  };

  system.stateVersion = 6;
  system.primaryUser = "lu";

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  # Ensure preferred shell is installed system-wide
  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];

  users.users.lu = {
    name = "lu";
    home = "/Users/lu";
    shell = pkgs.zsh;
  };

  system.activationScripts.extraActivation.text = ''
    echo "Setting shell for user lu to zsh..."

    ZSH_PATH="/run/current-system/sw/bin/zsh"
    CURRENT_SHELL=$(dscl . -read /Users/lu UserShell 2>/dev/null | awk '{print $2}')

    if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
      echo "Current shell: $CURRENT_SHELL"
      echo "Changing to: $ZSH_PATH"
      dscl . -create /Users/lu UserShell "$ZSH_PATH"
      echo "Shell changed successfully. You may need to restart your terminal."
    else
      echo "Shell is already set to zsh"
    fi
  '';
}
