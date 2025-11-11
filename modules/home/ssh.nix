{
  config,
  lib,
  pkgs,
  ...
}:
let
  sshDir = "${config.home.homeDirectory}/.ssh";
  secretsDir = ../../secrets/ssh;
  privateSecretFile = "${secretsDir}/id_ed25519";
  publicSecretFile = "${secretsDir}/id_ed25519.pub";

  bootstrapScript = ''
    #!/usr/bin/env bash
    set -euo pipefail

    SSH_DIR="${sshDir}"
    SSH_KEY="$SSH_DIR/id_ed25519"
    SSH_PUB_KEY="$SSH_DIR/id_ed25519.pub"

    if [ ! -f "$SSH_KEY" ] || [ ! -f "$SSH_PUB_KEY" ]; then
      echo "SSH keypair not found at $SSH_DIR. Run 'sudo darwin-rebuild switch --flake .#lu-mbp' after adding the encrypted secret." >&2
      exit 1
    fi

    if ! ${pkgs.gh}/bin/gh auth status >/dev/null 2>&1; then
      echo "Authenticating GitHub CLI (browser will open)..."
      PATH="/usr/bin:/bin:$PATH" \
        GIT_EXEC_PATH="${pkgs.git}/libexec/git-core" \
        ${pkgs.gh}/bin/gh auth login -p https -h github.com -w -s admin:public_key,admin:ssh_signing_key
    fi

    KEY_TITLE="$(/usr/sbin/scutil --get ComputerName)-$(date +%Y%m%d-%H%M%S)"
    SSH_KEY_CONTENT="$(awk '{print $1" "$2}' "$SSH_PUB_KEY")"

    if ! ${pkgs.gh}/bin/gh api /user/keys 2>/dev/null | grep -q "$SSH_KEY_CONTENT"; then
      PATH="/usr/bin:/bin:$PATH" \
        GIT_EXEC_PATH="${pkgs.git}/libexec/git-core" \
        ${pkgs.gh}/bin/gh ssh-key add "$SSH_PUB_KEY" --title "$KEY_TITLE"
    else
      echo "✓ SSH authentication key already present on GitHub"
    fi

    if ! ${pkgs.gh}/bin/gh api /user/ssh_signing_keys 2>/dev/null | grep -q "$SSH_KEY_CONTENT"; then
      PATH="/usr/bin:/bin:$PATH" \
        GIT_EXEC_PATH="${pkgs.git}/libexec/git-core" \
        ${pkgs.gh}/bin/gh ssh-key add "$SSH_PUB_KEY" --title "$KEY_TITLE" --type signing
    else
      echo "✓ SSH signing key already present on GitHub"
    fi

    echo "SSH bootstrap complete. Test with: ssh -T git@github.com"
  '';
in
{
  assertions = [
    {
      assertion = builtins.pathExists privateSecretFile;
      message = "Missing secrets/ssh/id_ed25519 (Age-encrypted SSH private key). Run 'nix shell nixpkgs#sops -c sops ${privateSecretFile}' to create it.";
    }
    {
      assertion = builtins.pathExists publicSecretFile;
      message = "Missing secrets/ssh/id_ed25519.pub (Age-encrypted SSH public key). Encrypt your .pub file with sops.";
    }
  ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      extraOptions = {
        AddKeysToAgent = "yes";
        UseKeychain = "yes";
      };
    };
  };

  home.activation.ensureSshDir = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    run mkdir -p '${sshDir}'
    run chmod 700 '${sshDir}'
  '';

  sops.secrets."ssh/id_ed25519" = {
    format = "binary";
    sopsFile = privateSecretFile;
    path = "${sshDir}/id_ed25519";
    mode = "0600";
  };

  sops.secrets."ssh/id_ed25519.pub" = {
    format = "binary";
    sopsFile = publicSecretFile;
    path = "${sshDir}/id_ed25519.pub";
    mode = "0644";
  };

  home.file."bin/bootstrap-ssh.sh" = {
    text = bootstrapScript;
    executable = true;
  };
}
