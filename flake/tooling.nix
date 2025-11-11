{ self, inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem =
    { pkgs, ... }:
    {
      # treefmt-nix configuration
      treefmt = {
        projectRootFile = "flake.nix";

        # Nix formatting with nixpkgs-fmt
        programs.nixpkgs-fmt.enable = true;

        # Linting for anti-patterns
        programs.statix.enable = true;

        # Dead code detection
        programs.deadnix.enable = true;

        # Global exclusions
        settings.global.excludes = [
          "*.lock"
          ".git/*"
          "result"
          "result-*"
        ];
      };

      checks = {
        darwin-lu-mbp = pkgs.runCommand "darwin-lu-mbp-check" { } ''
          export HOME=$TMPDIR
          ${pkgs.nix}/bin/nix build ${self}#darwinConfigurations.lu-mbp.system --no-link --print-out-paths
          touch $out
        '';

        # treefmt-nix automatically adds:
        # - treefmt = formatting check
      };
    };
}
