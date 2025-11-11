{ config
, lib
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

  # Idempotent permission enforcement for Age key
  # Ensures the sops-nix Age key has correct permissions (0600) on every activation
  home.activation.sopsAgeKeyPermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -f "${ageKeyFile}" ]; then
      run chmod 600 "${ageKeyFile}"
      $DRY_RUN_CMD echo "✓ Enforced 0600 permissions on Age key: ${ageKeyFile}"
    else
      $DRY_RUN_CMD echo "⚠ Age key not found (run bin/infisical-bootstrap-sops first): ${ageKeyFile}"
    fi
  '';
}
