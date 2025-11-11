{
  config,
  lib,
  pkgs,
  ...
}:
let
  sshPubSecretName = "ssh/id_ed25519.pub";
  hasManagedSshKey = config.sops.secrets ? sshPubSecretName;
  allowedSigners = "${config.xdg.configHome}/git/allowed_signers";
in
{
  programs.git = {
    enable = true;
    userName = "lumirth";
    userEmail = "65358837+lumirth@users.noreply.github.com";

    signing = lib.mkIf hasManagedSshKey {
      key = config.sops.secrets."${sshPubSecretName}".path;
      signByDefault = true;
    };

    extraConfig = {
      # Use SSH for commit signing
      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = allowedSigners;

      # Additional Git settings
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };

    # Git aliases for common operations
    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      visual = "!gitk";
    };
  };

  home.activation.setupAllowedSigners = lib.mkIf hasManagedSshKey (
    lib.hm.dag.entryAfter [ "sops-install-secrets" ] ''
      ALLOWED_SIGNERS='${allowedSigners}'
      SSH_PUB_FILE='${config.sops.secrets."${sshPubSecretName}".path}'

      if [ ! -f "$SSH_PUB_FILE" ]; then
        warnEcho "sops-nix key $SSH_PUB_FILE not found; skipping allowed_signers update"
        exit 0
      fi

      run mkdir -p "$(dirname "$ALLOWED_SIGNERS")"
      noteEcho "Updating git allowed_signers at $ALLOWED_SIGNERS"
      ${pkgs.coreutils}/bin/printf "%s %s\n" "${config.programs.git.userEmail}" "$(${pkgs.coreutils}/bin/cat "$SSH_PUB_FILE")" > "$ALLOWED_SIGNERS"
      run chmod 644 "$ALLOWED_SIGNERS"
    ''
  );
}
