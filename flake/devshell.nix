{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        name = "nix-darwin-dev";
        packages = with pkgs; [
          nix
          git
          sops
          age
          infisical
          nixpkgs-fmt
          nil
          nixd
          statix
          deadnix
          shellcheck
        ];

        shellHook = ''
          echo "Entered nix-darwin devshell (pkgs=${pkgs.system})"
          if [ ! -f "$HOME/.config/sops/age/keys.txt" ]; then
            echo "⚠️  Age key missing; run ./bin/infisical-bootstrap-sops before rebuilding."
          fi
        '';
      };
    };
}
