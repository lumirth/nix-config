{
  description = "Clean macOS configuration with nix-darwin and home-manager";

  inputs = {
    # Nixpkgs - the main package repository
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # nix-darwin - macOS system configuration
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home-manager - user environment configuration
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-homebrew - declarative Homebrew management
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Homebrew taps for declarative management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      ...
    }:
    {
      # macOS system configuration for lu-mbp
      darwinConfigurations."lu-mbp" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          # Main system configuration
          ./darwin.nix

          # Homebrew management through nix-homebrew
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              user = "lu";
              autoMigrate = true; # Migrate existing Homebrew installation

              # Declarative tap management
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
              };
              mutableTaps = false; # Fully declarative
            };
          }

          # Sync homebrew taps with nix-homebrew configuration
          (
            { config, ... }:
            {
              homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
            }
          )

          # User environment management through home-manager
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              users.lu = import ./home.nix;
            };
          }
        ];
      };
    };
}
