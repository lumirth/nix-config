{ ... }:
let
  repoRoot = ../.;
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        fmt = pkgs.runCommand "fmt-check" { } ''
          ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt --check ${repoRoot}
          touch $out
        '';

        darwin-lu-mbp = pkgs.runCommand "darwin-lu-mbp" { } ''
          export HOME=$TMPDIR
          ${pkgs.nix}/bin/nix build ${repoRoot}#darwinConfigurations.lu-mbp.system --no-link
          touch $out
        '';

        home-lu-mbp = pkgs.runCommand "home-lu-mbp" { } ''
          export HOME=$TMPDIR
          ${pkgs.nix}/bin/nix build ${repoRoot}#homeConfigurations."lu@lu-mbp".activationPackage --no-link
          touch $out
        '';
      };
    };
}
