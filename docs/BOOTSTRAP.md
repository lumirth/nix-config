# Bootstrap Guide

This guide walks you through setting up this nix-darwin configuration from scratch on a new macOS machine.

## Prerequisites

Before you begin, ensure you have:

1. **macOS** (Apple Silicon or Intel)
2. **Determinate Nix Installer** - Install from [https://determinate.systems/nix-installer](https://determinate.systems/nix-installer)
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```
3. **Git** - Should be available via Xcode Command Line Tools
   ```bash
   xcode-select --install
   ```

## Bootstrap Process

### Step 1: Clone the Configuration Repository

Clone this repository to `~/.config/nix`:

```bash
git clone <repository-url> ~/.config/nix
cd ~/.config/nix
```

### Step 2: Bootstrap Secrets (Age Key)

The configuration uses `sops-nix` to manage encrypted secrets. Before you can build the system, you need to retrieve the Age encryption key from Infisical.

#### Install Infisical CLI

```bash
brew install infisical/tap/infisical
```

#### Authenticate with Infisical

Follow the Infisical authentication process (this will open your browser):

```bash
infisical login
```

#### Fetch the Age Key

Run the bootstrap script to fetch the Age key from Infisical and save it to the correct location:

```bash
~/bin/infisical-bootstrap-sops
```

**What this does:**
- Fetches the `SOPS_AGE_KEY` secret from Infisical
- Saves it to `~/.config/sops/age/keys.txt` with correct permissions (0600)
- This key is required to decrypt all secrets in the `secrets/` directory

**Environment Variables (Optional):**

The script uses these defaults, which can be overridden:
- `INFISICAL_SECRET_NAME`: `SOPS_AGE_KEY` (the secret name in Infisical)
- `INFISICAL_ENVIRONMENT`: `prod` (the Infisical environment)
- `INFISICAL_PATH`: `/macos` (the path within the Infisical project)
- `INFISICAL_PROJECT_ID`: (optional, auto-detected if you have access to only one project)

Example with custom values:
```bash
INFISICAL_ENVIRONMENT=dev ~/bin/infisical-bootstrap-sops
```

### Step 3: Initial System Build

Now that secrets are available, build and activate the nix-darwin configuration:

```bash
cd ~/.config/nix
sudo darwin-rebuild switch --flake .#lu-mbp
```

**What this does:**
- Builds the complete system configuration (nix-darwin + home-manager)
- Applies macOS system settings and preferences
- Installs all packages and applications
- Decrypts and installs secrets (SSH keys, Rectangle Pro license, etc.)
- Configures shell, git, and other user environment settings

**Note:** This command applies both system-level (nix-darwin) and user-level (home-manager) configurations atomically. You don't need to run separate commands.

**First-time build:** The initial build may take 10-20 minutes as it downloads and builds all dependencies.

### Step 4: Authenticate GitHub CLI

After the initial system build, your SSH keys have been decrypted and placed in `~/.ssh/`. Now you need to authenticate with GitHub for SSH access and commit signing.

#### Add SSH Key to Keychain

First, add the SSH key to your macOS keychain:

```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

#### Authenticate with GitHub

The configuration uses declarative Git SSH signing, but you still need to authenticate GitHub CLI and upload your SSH keys manually:

```bash
# Authenticate with GitHub CLI (opens browser)
gh auth login -p https -h github.com -w -s admin:public_key,admin:ssh_signing_key

# Upload SSH key for authentication
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(scutil --get ComputerName) - $(date +%Y-%m-%d)"

# Upload SSH key for commit signing
gh ssh-key add ~/.ssh/id_ed25519.pub --type signing --title "$(scutil --get ComputerName) - Signing - $(date +%Y-%m-%d)"
```

**What this does:**
1. Authenticates GitHub CLI with required scopes (`admin:public_key`, `admin:ssh_signing_key`)
2. Uploads your SSH public key as an **authentication key** (for `git clone`, `git push`, etc.)
3. Uploads your SSH public key as a **signing key** (for commit signing)
4. Uses your computer name + timestamp as the key title for easy identification

**Verify SSH Access:**

Test that SSH authentication works:

```bash
ssh -T git@github.com
```

You should see: `Hi <username>! You've successfully authenticated...`

### Step 5: Verify the Installation

Check that everything is working correctly:

#### System Configuration

```bash
# Verify nix-darwin is active
darwin-rebuild --list-generations

# Check Determinate Nixd is running
sudo launchctl list | grep determinate

# Verify no conflicting GC daemon
sudo launchctl list | grep nix-gc  # Should return nothing
```

#### Home Manager

```bash
# Verify packages are available
which ripgrep fd bat eza zoxide

# Check shell configuration
echo $EDITOR  # Should show: zed

# Verify git configuration
git config --get user.name
git config --get user.email
git config --get gpg.format  # Should show: ssh
```

#### Secrets

```bash
# Verify Age key exists
ls -la ~/.config/sops/age/keys.txt  # Should show 0600 permissions

# Verify SSH keys are decrypted
ls -la ~/.ssh/id_ed25519  # Should show 0600 permissions
ls -la ~/.ssh/id_ed25519.pub  # Should show 0644 permissions

# Verify Rectangle Pro license (if applicable)
ls -la ~/Library/Application\ Support/Rectangle\ Pro/*.padl
```

#### Touch ID for sudo

Test Touch ID authentication in a terminal multiplexer:

```bash
# Start tmux
tmux new-session -s test

# Try sudo (should prompt for Touch ID)
sudo echo "Touch ID works!"

# Exit tmux
exit
```

## Post-Bootstrap Configuration

### Homebrew Applications

Homebrew casks are managed declaratively in `system.nix`. After the initial build, Homebrew applications should be installed automatically. Check:

```bash
ls /Applications/ | grep -E "Raycast|Slack|Visual Studio Code"
```

### Shell Restart

After the initial build, restart your shell to pick up all environment changes:

```bash
exec zsh
```

Or simply open a new terminal window.

## Troubleshooting

### Age Key Not Found

**Error:** `ERROR: sops secrets configured but Age key not found.`

**Solution:** Run the Infisical bootstrap script:
```bash
~/bin/infisical-bootstrap-sops
```

### Infisical CLI Not Found

**Error:** `error: Infisical CLI not found in PATH.`

**Solution:** Install Infisical:
```bash
brew install infisical/tap/infisical
infisical login
```

### SSH Keys Not Decrypted

**Error:** SSH keys missing from `~/.ssh/`

**Solution:** Ensure the Age key is present and rebuild:
```bash
ls ~/.config/sops/age/keys.txt  # Verify Age key exists
sudo darwin-rebuild switch --flake ~/.config/nix#lu-mbp
```

### GitHub CLI Authentication Failed

**Error:** `gh auth status` fails or shows insufficient scopes

**Solution:** Re-authenticate with required scopes:
```bash
gh auth login -p https -h github.com -w -s admin:public_key,admin:ssh_signing_key
```

### Build Fails with "nix.enable must be false"

**Error:** Assertion failure about `nix.enable`

**Solution:** This is expected. The configuration uses Determinate Nix, which manages the Nix daemon directly. Ensure `nix.enable = false;` is not overridden in your configuration.

### Touch ID Not Working in tmux

**Error:** Touch ID prompts don't appear in tmux/screen

**Solution:** Verify the `reattach` parameter is set:
```bash
# Check the configuration
grep -r "reattach" ~/.config/nix/darwin/defaults.nix

# Should show: reattach = true;
```

If missing, rebuild:
```bash
sudo darwin-rebuild switch --flake ~/.config/nix#lu-mbp
```

## Next Steps

After successful bootstrap:

1. **Customize the configuration** - Edit files in `~/.config/nix/` to add packages, change settings, etc.
2. **Apply changes** - Run `sudo darwin-rebuild switch --flake ~/.config/nix#lu-mbp`
3. **Commit changes** - Use git to track your configuration changes
4. **Read the rollback guide** - See `docs/ROLLBACK.md` for recovery procedures

## Configuration Files Overview

This configuration uses a simplified **4-file structure** optimized for single-machine use:

- **flake.nix** - Entry point with all inputs, outputs, nixpkgs instantiation, devShell, and checks
- **system.nix** - Complete nix-darwin configuration (Determinate Nix, Homebrew, macOS defaults, Dock, app preferences)
- **home.nix** - Complete home-manager configuration (packages, shell, Git, SSH, secrets)
- **pkgs/claude-code-acp/default.nix** - Custom package definition

**Key Benefits:**
- 64% reduction in file count from previous structure
- Single source of truth for each concern
- No framework abstractions (vanilla flake structure)
- Declarative-first patterns throughout
- Easy to navigate and understand

## Additional Resources

- [nix-darwin Documentation](https://github.com/LnL7/nix-darwin)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Determinate Systems](https://determinate.systems/)
- [sops-nix Documentation](https://github.com/Mic92/sops-nix)
- [Infisical Documentation](https://infisical.com/docs)
