{ self, ... }:
{
  perSystem =
    { config, pkgs, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs = {
          nixpkgs-fmt.enable = true;
          statix.enable = true;
          deadnix.enable = true;
          shellcheck.enable = true;
        };
        settings.global.excludes = [
          "secrets/**"
        ];
      };

      formatter = config.treefmt.build.wrapper;

      checks = {
        fmt = config.treefmt.build.check;

        darwin-lu-mbp = pkgs.runCommand "darwin-lu-mbp-check" { } ''
          export HOME=$TMPDIR
          ${pkgs.nix}/bin/nix build ${self}#darwinConfigurations.lu-mbp.system --no-link --print-out-paths
          touch $out
        '';
      };
    };
}
