{ config
, inputs
, ...
}:
let
  ageKeyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
in
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops.age.keyFile = ageKeyFile;
  # Age key hydration must happen manually (see devshell hook).
}
