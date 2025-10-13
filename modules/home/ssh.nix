{
  config,
  lib,
  pkgs,
  ...
}:
{
  # SSH configuration for Keychain integration
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

  # Setup SSH key and GitHub authentication
  home.activation.setupSSH = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SSH_DIR="$HOME/.ssh"
    SSH_KEY="$SSH_DIR/id_ed25519"
    SSH_PUB_KEY="$SSH_KEY.pub"
    EMAIL="65358837+lumirth@users.noreply.github.com"

    # Create .ssh directory if it doesn't exist
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"

    # Generate SSH key if it doesn't exist
    if [ ! -f "$SSH_KEY" ]; then
      echo "=========================================="
      echo "Generating new SSH key..."
      echo "=========================================="
      echo "You will be prompted to set a passphrase to protect your SSH key."
      echo "This passphrase will be stored securely in your macOS Keychain."
      echo ""

      # Generate key with passphrase prompt (no -N flag means interactive)
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_KEY"

      if [ -f "$SSH_KEY" ]; then
        echo ""
        echo "✓ SSH key generated at $SSH_KEY"
        echo ""
        echo "=========================================="
        echo "⚠️  IMPORTANT: Add SSH Key to Keychain"
        echo "=========================================="
        echo ""
        echo "After bootstrap completes, run this command:"
        echo ""
        echo "    ssh-add --apple-use-keychain $SSH_KEY"
        echo ""
        echo "This will save your passphrase to macOS Keychain so you only enter it once."
        echo "=========================================="
      else
        echo "Error: SSH key generation may have been cancelled"
      fi
    else
      echo "✓ SSH key already exists at $SSH_KEY"
      echo ""
      echo "To ensure it's in Keychain, run:"
      echo "    ssh-add --apple-use-keychain $SSH_KEY"
      echo ""
    fi

    # Step 1: Authenticate with GitHub CLI
    echo ""
    echo "=========================================="
    echo "Step 1: GitHub CLI Authentication"
    echo "=========================================="

    if ! ${pkgs.gh}/bin/gh auth status >/dev/null 2>&1; then
      echo "Please authenticate with GitHub..."
      echo "This will open your browser for authentication."
      # Set PATH and GIT_EXEC_PATH so gh can find open and git
      PATH="/usr/bin:/bin:$PATH" GIT_EXEC_PATH="${pkgs.git}/libexec/git-core" ${pkgs.gh}/bin/gh auth login -p https -h github.com -w -s admin:public_key,admin:ssh_signing_key
      echo "✓ GitHub CLI authenticated"
    else
      echo "✓ Already authenticated with GitHub CLI"
    fi

    # Check if we have the required scopes
    if ! ${pkgs.gh}/bin/gh ssh-key list >/dev/null 2>&1; then
      echo ""
      echo "Requesting SSH key management permissions..."
      PATH="/usr/bin:/bin:$PATH" GIT_EXEC_PATH="${pkgs.git}/libexec/git-core" ${pkgs.gh}/bin/gh auth refresh -h github.com -s admin:public_key,admin:ssh_signing_key

      # Verify the scope was granted
      if ! ${pkgs.gh}/bin/gh ssh-key list >/dev/null 2>&1; then
        echo "⚠️  Warning: Could not verify admin:public_key scope"
        echo "   You may need to manually add SSH keys"
      else
        echo "✓ Permissions granted"
      fi
    fi

    # Step 2: Add SSH key to GitHub
    echo ""
    echo "=========================================="
    echo "Step 2: Adding SSH Key to GitHub"
    echo "=========================================="

    if ${pkgs.gh}/bin/gh auth status >/dev/null 2>&1; then
      KEY_TITLE="$(/usr/sbin/scutil --get ComputerName)-$(date +%Y%m%d-%H%M%S)"
      SSH_KEY_CONTENT="$(cat "$SSH_PUB_KEY" | /usr/bin/awk '{print $1" "$2}')"

      # Add as authentication key
      AUTH_KEY_EXISTS=$(${pkgs.gh}/bin/gh api /user/keys 2>/dev/null | grep -q "$SSH_KEY_CONTENT" && echo "yes" || echo "no")

      if [ "$AUTH_KEY_EXISTS" = "yes" ]; then
        echo "✓ SSH authentication key already exists on GitHub"
      else
        echo "Adding SSH authentication key as '$KEY_TITLE'..."
        if PATH="/usr/bin:/bin:$PATH" GIT_EXEC_PATH="${pkgs.git}/libexec/git-core" ${pkgs.gh}/bin/gh ssh-key add "$SSH_PUB_KEY" --title "$KEY_TITLE" 2>/dev/null; then
          echo "✓ SSH authentication key added to GitHub"
        else
          echo "⚠️  Could not add SSH authentication key automatically"
          echo "   You can add it manually with:"
          echo "   gh ssh-key add $SSH_PUB_KEY --title '$KEY_TITLE'"
        fi
      fi

      # Add as signing key
      SIGNING_KEY_EXISTS=$(${pkgs.gh}/bin/gh api /user/ssh_signing_keys 2>/dev/null | grep -q "$SSH_KEY_CONTENT" && echo "yes" || echo "no")

      if [ "$SIGNING_KEY_EXISTS" = "yes" ]; then
        echo "✓ SSH signing key already exists on GitHub"
      else
        # Small delay to avoid rate limiting
        sleep 1
        echo "Adding SSH signing key as '$KEY_TITLE'..."
        if PATH="/usr/bin:/bin:$PATH" GIT_EXEC_PATH="${pkgs.git}/libexec/git-core" ${pkgs.gh}/bin/gh ssh-key add "$SSH_PUB_KEY" --title "$KEY_TITLE" --type signing 2>/dev/null; then
          echo "✓ SSH signing key added to GitHub"
          echo "  Your commits will now show as verified!"
        else
          echo "⚠️  Could not add SSH signing key automatically"
          echo "   You can add it manually with:"
          echo "   gh ssh-key add $SSH_PUB_KEY --title '$KEY_TITLE' --type signing"
        fi
      fi
    else
      echo "⚠️  Not authenticated with GitHub - skipping key addition"
    fi
  '';
}
