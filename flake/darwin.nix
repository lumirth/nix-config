{
  self,
  inputs,
  lib,
  ...
}:
let
  # Import shared nixpkgs configuration (single source of truth)
  nixpkgsConfig = import ./nixpkgs-config.nix { inherit lib; };
in
{
  flake = {
    darwinConfigurations.lu-mbp = inputs.nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = { inherit inputs self; };
      modules = [
        inputs.determinate.darwinModules.default
        inputs.nix-homebrew.darwinModules.nix-homebrew
        inputs.home-manager.darwinModules.home-manager
        ../system.nix
        {
          # Apply centralized nixpkgs configuration
          nixpkgs.config = nixpkgsConfig;

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          # Handle file collisions gracefully during activation
          # When Home Manager tries to create a symlink but a file already exists,
          # rename the existing file with .backup extension instead of failing.
          # This is essential for:
          # - Initial migration from imperative to declarative configuration
          # - Conflict resolution when multiple tools manage the same file
          # - Safety: original files are preserved, not deleted
          home-manager.backupFileExtension = "backup";

          home-manager.extraSpecialArgs = { inherit inputs self; };
          home-manager.users.lu = import ../home.nix;
        }
      ];
    };

    # Standalone home configuration for testing home-manager changes independently
    # This allows running: home-manager switch --flake .#lu
    # without requiring a full system rebuild via darwin-rebuild
    homeConfigurations.lu = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        system = "aarch64-darwin";
        config = nixpkgsConfig;
      };
      extraSpecialArgs = { inherit inputs self; };
      modules = [
        ../home.nix
      ];
    };
  };
}
