{
  config,
  lib,
  pkgs,
  ...
}:
let
  gitEmail = config.programs.git.userEmail or "65358837+lumirth@users.noreply.github.com";
  bootstrapScript = ''
    #!/usr/bin/env bash
    set -euo pipefail

    SSH_KEY="$HOME/.ssh/id_ed25519.pub"

    if [ ! -f "$SSH_KEY" ]; then
      echo "SSH key not found at $SSH_KEY. Run 'darwin-rebuild switch' first." >&2
      exit 1
    fi

    if ! ${pkgs.gh}/bin/gh auth status >/dev/null 2>&1; then
      echo "Authenticating GitHub CLI (browser will open)..."
      PATH="/usr/bin:/bin:$PATH" \
        GIT_EXEC_PATH="${pkgs.git}/libexec/git-core" \
        ${pkgs.gh}/bin/gh auth login -p https -h github.com -w -s admin:public_key,admin:ssh_signing_key
    fi

    KEY_TITLE="$(/usr/sbin/scutil --get ComputerName)-$(date +%Y%m%d-%H%M%S)"
    SSH_KEY_CONTENT="$(awk '{print $1" "$2}' "$SSH_KEY")"

    if ! ${pkgs.gh}/bin/gh api /user/keys 2>/dev/null | grep -q "$SSH_KEY_CONTENT"; then
      PATH="/usr/bin:/bin:$PATH" \
        GIT_EXEC_PATH="${pkgs.git}/libexec/git-core" \
        ${pkgs.gh}/bin/gh ssh-key add "$SSH_KEY" --title "$KEY_TITLE"
    else
      echo "✓ SSH authentication key already present on GitHub"
    fi

    if ! ${pkgs.gh}/bin/gh api /user/ssh_signing_keys 2>/dev/null | grep -q "$SSH_KEY_CONTENT"; then
      PATH="/usr/bin:/bin:$PATH" \
        GIT_EXEC_PATH="${pkgs.git}/libexec/git-core" \
        ${pkgs.gh}/bin/gh ssh-key add "$SSH_KEY" --title "$KEY_TITLE" --type signing
    else
      echo "✓ SSH signing key already present on GitHub"
    fi

    echo "SSH bootstrap complete. Test with: ssh -T git@github.com"
  '';
in
{
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

  home.file."bin/bootstrap-ssh.sh" = {
    text = bootstrapScript;
    executable = true;
  };

  home.activation.setupSSH = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SSH_DIR="$HOME/.ssh"
    SSH_KEY="$SSH_DIR/id_ed25519"
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"

    if [ ! -f "$SSH_KEY" ]; then
      echo "Generating SSH key at $SSH_KEY"
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" -C "${gitEmail}" -f "$SSH_KEY" >/dev/null
      echo "Add the key to your macOS keychain with:"
      echo "  ssh-add --apple-use-keychain $SSH_KEY"
    else
      echo "✓ SSH key already exists at $SSH_KEY"
    fi
  '';
}
