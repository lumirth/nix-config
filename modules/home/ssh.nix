{
  config,
  lib,
  pkgs,
  ...
}:
{
  # SSH configuration for macOS keychain integration
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

  # Automated SSH key generation and GitHub integration
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

      # Generate key with passphrase prompt
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_KEY"

      if [ -f "$SSH_KEY" ]; then
        echo ""
        echo "✓ SSH key generated at $SSH_KEY"
        echo ""
        echo "=========================================="
        echo "⚠️  IMPORTANT: Add SSH Key to Keychain"
        echo "=========================================="
        echo ""
        echo "After this completes, run:"
        echo "    ssh-add --apple-use-keychain $SSH_KEY"
        echo ""
        echo "This saves your passphrase to macOS Keychain."
        echo "=========================================="
      else
        echo "Error: SSH key generation may have been cancelled"
      fi
    else
      echo "✓ SSH key already exists at $SSH_KEY"

      # Check if key is in keychain
      if ! ssh-add -l 2>/dev/null | grep -q "$(ssh-keygen -lf "$SSH_PUB_KEY" 2>/dev/null | /usr/bin/awk '{print $2}')"; then
        echo ""
        echo "To add existing key to Keychain, run:"
        echo "    ssh-add --apple-use-keychain $SSH_KEY"
        echo ""
      fi
    fi

    # GitHub CLI Authentication and Key Management
    echo ""
    echo "=========================================="
    echo "GitHub CLI Authentication & Key Setup"
    echo "=========================================="

    # Check if GitHub CLI is authenticated
    if ! ${pkgs.gh}/bin/gh auth status >/dev/null 2>&1; then
      echo "Authenticating with GitHub CLI..."
      echo "This will open your browser for authentication."

      # Authenticate with required scopes
      if PATH="/usr/bin:/bin:$PATH" GIT_EXEC_PATH="${pkgs.git}/libexec/git-core" ${pkgs.gh}/bin/gh auth login -p https -h github.com -w -s admin:public_key,admin:ssh_signing_key; then
        echo "✓ GitHub CLI authenticated successfully"
      else
        echo "⚠️  GitHub CLI authentication failed - skipping key upload"
        exit 0
      fi
    else
      echo "✓ Already authenticated with GitHub CLI"

      # Verify we have the required scopes
      if ! ${pkgs.gh}/bin/gh ssh-key list >/dev/null 2>&1; then
        echo "Requesting additional permissions for SSH key management..."
        PATH="/usr/bin:/bin:$PATH" GIT_EXEC_PATH="${pkgs.git}/libexec/git-core" ${pkgs.gh}/bin/gh auth refresh -h github.com -s admin:public_key,admin:ssh_signing_key
      fi
    fi

    # Add SSH keys to GitHub if authenticated and key exists
    if ${pkgs.gh}/bin/gh auth status >/dev/null 2>&1 && [ -f "$SSH_PUB_KEY" ]; then
      echo ""
      echo "Adding SSH keys to GitHub..."

      KEY_TITLE="$(/usr/sbin/scutil --get ComputerName)-$(date +%Y%m%d-%H%M%S)"
      SSH_KEY_CONTENT="$(cat "$SSH_PUB_KEY" | /usr/bin/awk '{print $1" "$2}')"

      # Check if authentication key already exists
      if ${pkgs.gh}/bin/gh api /user/keys 2>/dev/null | grep -q "$SSH_KEY_CONTENT"; then
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

      # Check if signing key already exists
      if ${pkgs.gh}/bin/gh api /user/ssh_signing_keys 2>/dev/null | grep -q "$SSH_KEY_CONTENT"; then
        echo "✓ SSH signing key already exists on GitHub"
      else
        # Brief delay to avoid rate limiting
        sleep 1
        echo "Adding SSH signing key as '$KEY_TITLE'..."
        if PATH="/usr/bin:/bin:$PATH" GIT_EXEC_PATH="${pkgs.git}/libexec/git-core" ${pkgs.gh}/bin/gh ssh-key add "$SSH_PUB_KEY" --title "$KEY_TITLE" --type signing 2>/dev/null; then
          echo "✓ SSH signing key added to GitHub"
          echo "  Your commits will now show as verified! 🎉"
        else
          echo "⚠️  Could not add SSH signing key automatically"
          echo "   You can add it manually with:"
          echo "   gh ssh-key add $SSH_PUB_KEY --title '$KEY_TITLE' --type signing"
        fi
      fi
    else
      if [ ! -f "$SSH_PUB_KEY" ]; then
        echo "⚠️  No SSH public key found - skipping GitHub key upload"
      else
        echo "⚠️  Not authenticated with GitHub - skipping key upload"
        echo "   Run 'gh auth login' to authenticate and upload keys manually"
      fi
    fi

    echo ""
    echo "=========================================="
    echo "SSH Setup Complete"
    echo "=========================================="

    if [ -f "$SSH_KEY" ]; then
      echo "✓ SSH key: $SSH_KEY"
      if ${pkgs.gh}/bin/gh auth status >/dev/null 2>&1; then
        echo "✓ GitHub: Authenticated and keys uploaded"
      else
        echo "⚠️  GitHub: Not authenticated (manual setup required)"
      fi
    fi

    echo ""
    echo "Next steps:"
    echo "1. Add key to Keychain: ssh-add --apple-use-keychain $SSH_KEY"
    echo "2. Test SSH connection: ssh -T git@github.com"
    echo ""
  '';
}
