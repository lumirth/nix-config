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
  };

  outputs =
    inputs@{ self, ... }:
    let
      system = "aarch64-darwin";

      # Shared nixpkgs configuration (single source of truth)
      # Explicit unfree package whitelist for better security and licensing control
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
          ];
      };

      # Custom package overlay
      customPkgsOverlay = _final: prev: {
        claude-code-acp = prev.callPackage ./pkgs/claude-code-acp { };
      };

      # Instantiate nixpkgs with config and overlay
      pkgs = import inputs.nixpkgs {
        inherit system;
        config = nixpkgsConfig;
        overlays = [ customPkgsOverlay ];
      };

      # treefmt-nix configuration
      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";

        # Nix formatting with nixfmt (RFC-166)
        programs.nixfmt.enable = true;

        # Linting for anti-patterns
        programs.statix.enable = true;

        # Dead code detection
        programs.deadnix.enable = true;

        # Global exclusions
        settings.global.excludes = [
          "*.lock"
          ".git/*"
          "result"
          "result-*"
        ];
      };
    in
    {
      # Darwin system configuration
      darwinConfigurations.lu-mbp = inputs.nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = {
          inherit inputs self pkgs;
        };
        modules = [
          inputs.determinate.darwinModules.default
          inputs.nix-homebrew.darwinModules.nix-homebrew
          inputs.home-manager.darwinModules.home-manager
          ./system.nix
          {
            # Apply centralized nixpkgs configuration
            nixpkgs.config = nixpkgsConfig;

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.extraSpecialArgs = {
              inherit inputs self pkgs;
            };
            home-manager.users.lu = import ./home.nix;
          }
        ];
      };

      # Development shell
      devShells.${system}.default = pkgs.mkShell {
        name = "nix-darwin-dev";
        packages = with pkgs; [
          nix
          git
          sops
          age
          infisical
          nil
          nixd
        ];

        shellHook = ''
          echo "Entered nix-darwin devshell (pkgs=${system})"
          if [ ! -f "$HOME/.config/sops/age/keys.txt" ]; then
            echo "⚠️  Age key missing; run ./bin/infisical-bootstrap-sops before rebuilding."
          fi
        '';
      };

      # Checks
      checks.${system} = {
        darwin-lu-mbp = pkgs.runCommand "darwin-lu-mbp-check" { } ''
          export HOME=$TMPDIR
          ${pkgs.nix}/bin/nix build ${self}#darwinConfigurations.lu-mbp.system --no-link --print-out-paths
          touch $out
        '';

        # Formatting check from treefmt
        formatting = treefmtEval.config.build.check self;
      };

      # Formatter from treefmt
      formatter.${system} = treefmtEval.config.build.wrapper;
    };
}
