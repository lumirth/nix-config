{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.git = {
    enable = true;
    userName = "lumirth";
    userEmail = "65358837+lumirth@users.noreply.github.com";

    signing = {
      key = "~/.ssh/id_ed25519.pub";
      signByDefault = true;
    };

    extraConfig = {
      # This tells git: "Use SSH for signing, NOT GPG"
      # (Confusing naming, but gpg.format = "ssh" means "don't use gpg")
      gpg.format = "ssh";
      # Enable local signature verification
      gpg.ssh.allowedSignersFile = "~/.config/git/allowed_signers";
    };
  };

  # Generate allowed_signers file for local SSH signature verification
  home.activation.setupAllowedSigners = lib.hm.dag.entryAfter [ "setupSSH" ] ''
    ALLOWED_SIGNERS="$HOME/.config/git/allowed_signers"
    SSH_PUB_KEY="$HOME/.ssh/id_ed25519.pub"

    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$ALLOWED_SIGNERS")"

    # Generate allowed_signers file if SSH key exists
    if [ -f "$SSH_PUB_KEY" ]; then
      echo "Setting up SSH allowed signers for local verification..."
      echo "65358837+lumirth@users.noreply.github.com $(cat "$SSH_PUB_KEY")" > "$ALLOWED_SIGNERS"
      echo "Created $ALLOWED_SIGNERS"
    else
      echo "Warning: SSH key not found at $SSH_PUB_KEY"
    fi
  '';
}
