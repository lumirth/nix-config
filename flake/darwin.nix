{
  self,
  inputs,
  lib,
  ...
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
in
{
  flake = {
    darwinConfigurations = lib.mapAttrs (
      hostName:
      {
        system,
        module,
        user,
        homeModule,
        ...
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
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs self; };
            home-manager.users.${user} = homeModule;
          }
        ];
      }
    ) hosts;
  };
}
