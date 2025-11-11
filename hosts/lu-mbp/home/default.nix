{ inputs, ... }:
{
  imports = [
    ../../../modules/home/packages.nix
    ../../../modules/home/shell.nix
    ../../../modules/home/git.nix
    ../../../modules/home/ssh.nix
    ../../../modules/home/fonts.nix
    ../../../modules/home/sops.nix
    ../../../modules/home/apps/rectangle-pro.nix
  ];

  home = {
    stateVersion = "25.05";
    username = "lu";
    homeDirectory = "/Users/lu";
  };
}
