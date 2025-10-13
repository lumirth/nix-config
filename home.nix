{ ... }:
{
  imports = [
    ./modules/home/packages.nix
    ./modules/home/shell.nix
    ./modules/home/git.nix
    ./modules/home/ssh.nix
  ];

  home = {
    stateVersion = "25.05";
    username = "lu";
    homeDirectory = "/Users/lu";
  };
}
