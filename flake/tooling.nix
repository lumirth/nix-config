{ self, ... }:
{
  perSystem =
    { config, pkgs, ... }:
    {
      formatter = pkgs.nixpkgs-fmt;

      checks = {
        darwin-lu-mbp = pkgs.runCommand "darwin-lu-mbp-check" { } ''
          export HOME=$TMPDIR
          ${pkgs.nix}/bin/nix build ${self}#darwinConfigurations.lu-mbp.system --no-link --print-out-paths
          touch $out
        '';
      };
    };
}
