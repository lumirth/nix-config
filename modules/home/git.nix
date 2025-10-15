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
      # Use SSH for commit signing
      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = "~/.config/git/allowed_signers";

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

  # Setup allowed_signers file for SSH signature verification
  home.activation.setupAllowedSigners = lib.hm.dag.entryAfter [ "setupSSH" ] ''
    ALLOWED_SIGNERS="$HOME/.config/git/allowed_signers"
    SSH_PUB_KEY="$HOME/.ssh/id_ed25519.pub"

    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$ALLOWED_SIGNERS")"

    # Generate allowed_signers file if SSH key exists
    if [ -f "$SSH_PUB_KEY" ]; then
      echo "Setting up SSH allowed signers for local verification..."
      echo "65358837+lumirth@users.noreply.github.com $(cat "$SSH_PUB_KEY" | /usr/bin/awk '{print $1" "$2}')" > "$ALLOWED_SIGNERS"
      echo "Created $ALLOWED_SIGNERS"
    else
      echo "Warning: SSH key not found at $SSH_PUB_KEY"
      echo "Skipping allowed_signers setup"
    fi
  '';
}
