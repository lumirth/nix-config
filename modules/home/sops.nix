{ config, inputs, lib, ... }:
let
  bootstrapScript = "${config.home.homeDirectory}/.config/nix/bin/infisical-bootstrap-sops";
  ageKeyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
in
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops.age.keyFile = ageKeyFile;

  home.activation.bootstrapAgeKey = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    if [ ! -x '${bootstrapScript}' ]; then
      warnEcho "infisical bootstrap script missing at ${bootstrapScript}; skipping"
    elif [ ! -s '${ageKeyFile}' ]; then
      noteEcho "Hydrating Age key via Infisical"
      run ${bootstrapScript}
    fi
  '';
}
