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

    # Determinate Systems - declarative Nix settings on macOS
    determinate = {
      url = "github:DeterminateSystems/determinate";
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

    # sops-nix - encrypted secrets management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      determinate,
      ...
    }:
    let
      system = "aarch64-darwin";
      hosts = {
        "lu-mbp" = ./hosts/lu-mbp;
      };
    in
    {
      darwinConfigurations = builtins.mapAttrs (
        hostName: hostModule:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            determinate.darwinModules.default
            hostModule
          ];
        }
      ) hosts;
    };
}
