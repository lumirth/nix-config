{ config
, lib
, pkgs
, ...
}:
let
  sshPubSecretName = "ssh/id_ed25519.pub";
  hasManagedSshKey = config.sops.secrets ? sshPubSecretName;
  sshPubKeyPath = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
  allowedSigners = "${config.home.homeDirectory}/.config/git/allowed_signers";
in
{
  programs.git = {
    enable = true;
    userName = "lumirth";
    userEmail = "65358837+lumirth@users.noreply.github.com";

    signing = lib.mkIf hasManagedSshKey {
      key = sshPubKeyPath;
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
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ALLOWED_SIGNERS='${allowedSigners}'
      SSH_PUB_FILE='${config.sops.secrets."${sshPubSecretName}".path}'

      run mkdir -p "$(dirname "$ALLOWED_SIGNERS")"
      PUB_KEY="$(${pkgs.coreutils}/bin/awk '{print $1" "$2}' "$SSH_PUB_FILE")"
      cat >"$ALLOWED_SIGNERS" <<EOF
${config.programs.git.userEmail or "65358837+lumirth@users.noreply.github.com"} $PUB_KEY
EOF
      chmod 600 "$ALLOWED_SIGNERS"
      noteEcho "Updated $ALLOWED_SIGNERS for SSH signing"
    ''
  );
}
