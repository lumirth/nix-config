{ self
, inputs
, lib
, ...
}:
let
  hosts = {
    lu-mbp = {
      system = "aarch64-darwin";
      module = ../hosts/lu-mbp/system;
      user = "lu";
      homeModule = ../hosts/lu-mbp/home;
    };
  };

  mkPkgs =
    system:
    import inputs.nixpkgs {
      inherit system;
      overlays = [ self.overlays.default ];
      config.allowUnfree = true;
    };
in
{
  flake = {
    darwinConfigurations = lib.mapAttrs
      (
        hostName:
        { system, module, ... }:
        inputs.nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit inputs self; };
          modules = [
            inputs.determinate.darwinModules.default
            inputs.nix-homebrew.darwinModules.nix-homebrew
            module
          ];
        }
      )
      hosts;

    homeConfigurations = lib.mapAttrs'
      (
        hostName:
        { system
        , user
        , homeModule
        , ...
        }:
        lib.nameValuePair "${user}@${hostName}" (
          inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = mkPkgs system;
            extraSpecialArgs = { inherit inputs self; };
            modules = [
              homeModule
            ];
          }
        )
      )
      hosts;
  };
}
