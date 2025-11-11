# Overlay Definition (flake-parts pattern)
# =========================================
# 
# This overlay follows the modern final: prev: convention for composability.
# 
# Arguments:
# - final: The complete, fixed-point package set after ALL overlays are applied
#   Use 'final' when:
#   - Calling callPackage (ensures we get the final version of callPackage)
#   - Referencing dependencies that might be modified by other overlays
#   - Defining new packages that depend on other packages
# 
# - prev: The package set BEFORE this overlay is applied
#   Use 'prev' when:
#   - Modifying an existing package (prev.package.override { ... })
#   - Accessing the original version of a package you're replacing
# 
# Pattern used here:
# - final.callPackage: Ensures we use the final version of callPackage
# - Dependencies (buildNpmPackage, fetchFromGitHub, lib) are auto-injected by callPackage
# - If another overlay modifies these dependencies, our package automatically uses them
# 
# This overlay is:
# 1. Defined here as a pure function (system-agnostic)
# 2. Exported in flake.nix as flake.overlays.default
# 3. Applied in flake.nix perSystem block when instantiating pkgs
# 4. Available to all modules (darwin, home-manager, devshell)
final: _prev: {
  # Custom package: claude-code-acp
  # Use final.callPackage to ensure composability with other overlays
  claude-code-acp = final.callPackage
    (
      { buildNpmPackage, fetchFromGitHub, lib }:
      buildNpmPackage rec {
        pname = "claude-code-acp";
        version = "0.10.0";

        src = fetchFromGitHub {
          owner = "zed-industries";
          repo = "claude-code-acp";
          rev = "84b5744a2f458d22839521abf82925cad64f3617";
          hash = "sha256-ZbCumFZyGFoNBNK6PC56oauuN2Wco3rlR80/1rBPORk=";
        };

        npmDepsHash = "sha256-nzP2cMYKoe4S9goIbJ+ocg8bZPY/uCTOm0bLbn4m6Mw=";

        meta = with lib; {
          description = "Zed Claude Code assistant CLI";
          homepage = "https://github.com/zed-industries/claude-code-acp";
          license = licenses.asl20;
          mainProgram = "claude-code-acp";
          maintainers = [ ];
        };
      }
    )
    { };
}
