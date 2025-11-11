{
  description = "Clean macOS configuration with nix-darwin, home-manager, and sops-nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate = {
      url = "github:DeterminateSystems/determinate";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    let
      # Import shared nixpkgs configuration (single source of truth)
      nixpkgsConfig = import ./flake/nixpkgs-config.nix { inherit (inputs.nixpkgs) lib; };
    in
    flake-parts.lib.mkFlake
      {
        inherit inputs;
        specialArgs = { inherit self; };
      }
      {
        systems = [ "aarch64-darwin" ];

        # Per-system configuration
        # This block runs once for each system in the systems list (aarch64-darwin)
        perSystem =
          { system, pkgs, ... }:
          {
            # Instantiate nixpkgs with config (no overlays needed)
            # This creates the pkgs argument available to all perSystem modules
            #
            # Key components:
            # - system: The current system architecture (aarch64-darwin)
            # - config: nixpkgsConfig with allowUnfreePredicate for security
            #
            # The resulting pkgs is used by:
            # - flake/darwin.nix (for system packages and checks)
            # - flake/tooling.nix (for treefmt and validation tools)
            # - flake/devshell.nix (for development shell packages)
            _module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              config = nixpkgsConfig; # Apply unfree package whitelist
            };

            # Custom packages as flake outputs (modern Nix best practice)
            packages.claude-code-acp = pkgs.callPackage ./pkgs/claude-code-acp { };
          };

        imports = [
          ./flake/darwin.nix
          ./flake/tooling.nix
          ./flake/devshell.nix
        ];
      };
}
