{ inputs, config, ... }:
{
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
    inputs.home-manager.darwinModules.home-manager
    ../../modules/system.nix
    ../../modules/homebrew.nix
  ];

  nix-homebrew = {
    enable = true;
    user = "lu";
    autoMigrate = true;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
    mutableTaps = false;
  };

  # Keep homebrew taps in sync with nix-homebrew configuration
  homebrew.taps = builtins.attrNames config.nix-homebrew.taps;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.lu = import ../../users/lu/home.nix;
  };
}
