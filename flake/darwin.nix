{ self
, inputs
, lib
, ...
}:
let
  # Centralized nixpkgs configuration with explicit unfree package whitelist
  nixpkgsConfig = {
    allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
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

  hosts = {
    lu-mbp = {
      system = "aarch64-darwin";
      module = ../hosts/lu-mbp/system;
      user = "lu";
      homeModule = ../hosts/lu-mbp/home;
    };
  };
in
{
  flake = {
    darwinConfigurations = lib.mapAttrs
      (
        _hostName:
        { system
        , module
        , user
        , homeModule
        , ...
        }:
        inputs.nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit inputs self; };
          modules = [
            inputs.determinate.darwinModules.default
            inputs.nix-homebrew.darwinModules.nix-homebrew
            inputs.home-manager.darwinModules.home-manager
            module
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
              home-manager.users.${user} = homeModule;
            }
          ];
        }
      )
      hosts;
  };
}
