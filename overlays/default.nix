final: prev: {
  claude-code-acp = prev.buildNpmPackage rec {
    pname = "claude-code-acp";
    version = "0.10.0";

    src = prev.fetchFromGitHub {
      owner = "zed-industries";
      repo = "claude-code-acp";
      rev = "84b5744a2f458d22839521abf82925cad64f3617";
      hash = "sha256-ZbCumFZyGFoNBNK6PC56oauuN2Wco3rlR80/1rBPORk=";
    };

    npmDepsHash = "sha256-nzP2cMYKoe4S9goIbJ+ocg8bZPY/uCTOm0bLbn4m6Mw=";

    meta = with final.lib; {
      description = "Zed Claude Code assistant CLI";
      homepage = "https://github.com/zed-industries/claude-code-acp";
      license = licenses.asl20;
      mainProgram = "claude-code-acp";
      maintainers = [ ];
    };
  };
}
