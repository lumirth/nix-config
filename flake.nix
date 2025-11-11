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
      # Centralized nixpkgs configuration with explicit unfree package whitelist
      # This replaces the global allowUnfree = true for better security and licensing control
      nixpkgsConfig = {
        allowUnfreePredicate =
          pkg:
          builtins.elem (inputs.nixpkgs.lib.getName pkg) [
            # GUI Applications (installed via Homebrew casks, but may have Nix equivalents)
            "vscode" # Code editor - Microsoft proprietary license
            "cursor" # AI-powered code editor - proprietary license
            "obsidian" # Knowledge base - Obsidian EULA
            "slack" # Team communication - proprietary license

            # CLI Tools with unfree licenses
            "cursor-cli" # Cursor CLI tool - proprietary license
            "claude-code" # Anthropic's agentic coding tool - proprietary license

            # Add additional unfree packages here as needed with justification comments
          ];
      };
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
          { system, ... }:
          {
            # Instantiate nixpkgs with overlays and config
            # This creates the pkgs argument available to all perSystem modules
            # 
            # Key components:
            # - system: The current system architecture (aarch64-darwin)
            # - overlays: Applied in order, each can modify packages from previous overlays
            # - config: nixpkgsConfig with allowUnfreePredicate for security
            # 
            # The resulting pkgs is used by:
            # - flake/darwin.nix (for system packages and checks)
            # - flake/tooling.nix (for treefmt and validation tools)
            # - flake/devshell.nix (for development shell packages)
            _module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [ self.overlays.default ]; # Apply our custom overlay
              config = nixpkgsConfig; # Apply unfree package whitelist
            };
          };

        imports = [
          ./flake/darwin.nix
          ./flake/tooling.nix
          ./flake/devshell.nix
        ];

        # Overlay Architecture (flake-parts pattern)
        # ==========================================
        # 
        # In flake-parts, overlays follow a two-phase pattern:
        # 
        # 1. DEFINITION (here in flake.overlays.*):
        #    - Overlays are defined at the top level as system-agnostic functions
        #    - They are pure functions: (final: prev: { ... })
        #    - They don't depend on any specific system architecture
        #    - They become part of the flake's public API (flake.overlays.default)
        # 
        # 2. APPLICATION (in perSystem._module.args.pkgs):
        #    - Overlays are applied when instantiating pkgs for each system
        #    - This happens in the perSystem block above
        #    - The pkgs instance is created with: overlays = [ self.overlays.default ]
        #    - This ensures overlays are applied consistently across all systems
        # 
        # Why separate definition from application?
        # - Modularity: Other flakes can import and use our overlays
        # - Composability: Multiple overlays can be combined cleanly
        # - System-agnostic: Overlay logic doesn't need to know about aarch64-darwin
        # - Testability: Overlays can be tested independently of system config
        # 
        # Example flow:
        #   flake.overlays.default (defined here)
        #     ↓
        #   perSystem.pkgs (applied here with system-specific nixpkgs)
        #     ↓
        #   Available in all modules (darwin, home-manager, devshell)
        flake = {
          overlays.default = import ./overlays/default.nix;
        };
      };
}
