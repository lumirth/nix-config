# lu's nix-darwin configuration

A streamlined, single-machine macOS configuration using Determinate Nix, nix-darwin, home-manager, and sops-nix. This configuration follows modern Nix best practices with a simplified 4-file structure optimized for maintainability.

## Recent Simplification (v2.0)

This configuration was recently refactored from an 11-file structure to a 4-file structure, eliminating the flake-parts framework and consolidating all related configuration into single files. See the [Migration Notes](#migration-notes) section below for details.

## Prerequisites

- macOS with Xcode Command Line Tools installed
- Determinate Nix (installs the daemon + flakes support):

  ```bash
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  ```

- Infisical CLI (Homebrew formula `infisical/tap/infisical`) to hydrate the Age private key

## Quick Start

For detailed bootstrap instructions, see [docs/BOOTSTRAP.md](docs/BOOTSTRAP.md).

```bash
git clone https://github.com/lu-mbp/nix-config ~/.config/nix
cd ~/.config/nix

# 1) Hydrate the Age private key from Infisical
./bin/infisical-bootstrap-sops

# 2) Apply the unified system + home configuration
sudo darwin-rebuild switch --flake .#lu-mbp

# 3) Authenticate GitHub CLI and upload SSH keys
gh auth login -p https -h github.com -w -s admin:public_key,admin:ssh_signing_key
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(scutil --get ComputerName) - $(date +%Y-%m-%d)"
gh ssh-key add ~/.ssh/id_ed25519.pub --type signing --title "$(scutil --get ComputerName) - Signing - $(date +%Y-%m-%d)"
```

For rollback procedures, see [docs/ROLLBACK.md](docs/ROLLBACK.md).

## Architecture

This configuration uses a simplified 4-file structure designed for single-machine use:

```
~/.config/nix/
├── flake.nix                    # Entry point: inputs, outputs, nixpkgs config, overlays, devShell, checks
├── system.nix                   # Complete nix-darwin configuration
├── home.nix                     # Complete home-manager configuration
├── pkgs/
│   └── claude-code-acp/         # Custom packages (via overlay)
│       └── default.nix
└── secrets/
    └── ssh/
        └── secrets.yaml         # YAML-format encrypted secrets
```

### Key Design Principles

1. **Single Machine Optimization**: No unnecessary abstractions for multi-machine deployments
2. **Vanilla Flake Structure**: No framework abstractions (removed flake-parts)
3. **Declarative-First**: Pure declarative configuration without imperative activation scripts
4. **Single Source of Truth**: Each concern lives in exactly one file
5. **Fail-Fast Validation**: Build-time assertions catch configuration errors early
6. **Modern Nix Patterns**: RFC-166 formatting, overlay pattern for custom packages, YAML secrets

### Configuration Layers

**Flake Layer (flake.nix)**
- All flake inputs and outputs
- Nixpkgs instantiation with config and overlays
- Custom package overlay (claude-code-acp)
- darwinConfigurations output
- devShells output with Age key warning
- checks output (build validation + formatting)
- treefmt configuration

**System Layer (system.nix)**
- Determinate Nix configuration (`nix.enable = false`)
- Homebrew casks, brews, and Mac App Store apps
- macOS system defaults (NSGlobalDomain, Finder, screencapture)
- Dock configuration and application preferences
- Touch ID configuration with tmux/screen support
- System user and shell settings

**Home Layer (home.nix)**
- CLI tools and packages
- Shell configuration (zsh, starship, direnv, zoxide, fzf)
- Declarative Git configuration with SSH signing
- SSH configuration
- Secrets management via sops-nix
- Fonts and fontconfig
- Environment variables

## Repository Layout

### Core Configuration Files

- **flake.nix** – Vanilla flake entry point with all inputs, outputs, nixpkgs instantiation, overlays, devShell, and checks
- **system.nix** – Complete nix-darwin configuration (Determinate Nix, Homebrew, macOS defaults, Dock, app preferences, Touch ID)
- **home.nix** – Complete home-manager configuration (packages, shell, Git, SSH, secrets)
- **pkgs/claude-code-acp/default.nix** – Custom package integrated via overlay pattern

## Secrets Management

Secrets are managed using sops-nix with Age encryption. The Age private key is stored in Infisical and must be bootstrapped before building.

### Bootstrap Secrets

```bash
./bin/infisical-bootstrap-sops
```

This fetches the Age key from Infisical and writes it to `~/.config/sops/age/keys.txt`.

### SSH Keys

SSH keys are declaratively managed via sops-nix:
- Private and public keys stored encrypted in `secrets/ssh/secrets.yaml`
- Automatically decrypted to `~/.ssh/` during system build
- Git SSH signing configured declaratively via `programs.git.signing` and `home.file` for allowed_signers
- Upload to GitHub manually using `gh` CLI commands (see [docs/BOOTSTRAP.md](docs/BOOTSTRAP.md))

### Editing Secrets

```bash
nix shell nixpkgs#sops -c sops secrets/ssh/secrets.yaml
```

## Daily Commands

### Apply Configuration Changes

```bash
# Apply system + home changes atomically
sudo darwin-rebuild switch --flake .#lu-mbp

# Preview changes without applying
darwin-rebuild dry-build --flake .#lu-mbp

# Build without activating
nix build .#darwinConfigurations.lu-mbp.system --no-link
```

### Validation and Formatting

```bash
# Format all Nix files (RFC-166 compliant)
nix fmt

# Run comprehensive checks
nix flake check

# Update flake inputs
nix flake update
```

### Rollback

```bash
# Rollback to previous generation
darwin-rebuild rollback

# List available generations
darwin-rebuild --list-generations

# Rollback to specific generation
darwin-rebuild switch --rollback --generation 42
```

For detailed rollback procedures, see [docs/ROLLBACK.md](docs/ROLLBACK.md).

## Common Tasks

### Add a CLI Tool

Edit `home.nix` and add the package to `home.packages`:

```nix
home.packages = with pkgs; [
  ripgrep
  fd
  bat
  # Add your package here
];
```

Then apply: `sudo darwin-rebuild switch --flake .#lu-mbp`

### Add a GUI Application

Edit `system.nix` and add the cask to `homebrew.casks`:

```nix
homebrew = {
  enable = true;
  casks = [
    "raycast"
    "slack"
    # Add your cask here
  ];
};
```

Then apply: `sudo darwin-rebuild switch --flake .#lu-mbp`

### Configure macOS Settings

Edit `system.nix` to modify system preferences (look for the macOS defaults section):

```nix
system.defaults = {
  NSGlobalDomain = {
    AppleShowAllExtensions = true;
    # Add your settings here
  };
};
```

Then apply: `sudo darwin-rebuild switch --flake .#lu-mbp`

## Important Notes

1. **Determinate Nix**: This configuration uses Determinate Nix, which manages the Nix daemon directly. Therefore, `nix.enable = false` in the nix-darwin configuration.

2. **Declarative Only**: Avoid imperative commands like `nix-env -i`, `nix profile install`, or manual `defaults write`. All changes should be made in configuration files.

3. **Atomic Updates**: The single command `sudo darwin-rebuild switch --flake .#lu-mbp` applies both system and home-manager changes atomically.

4. **GUI Applications**: macOS GUI applications should be installed via Homebrew casks, not Nix packages.

5. **Build-Time Assertions**: The configuration includes assertions that catch common misconfigurations at build time, preventing broken deployments.

6. **RFC-166 Formatting**: All Nix files are formatted using nixfmt for consistency.

## Documentation

- [docs/BOOTSTRAP.md](docs/BOOTSTRAP.md) – Detailed bootstrap procedures for new machines
- [docs/ROLLBACK.md](docs/ROLLBACK.md) – Recovery procedures for failed configurations
- [AGENTS.md](AGENTS.md) – Guide for AI assistants working with this configuration

## Technology Stack

- **Nix Distribution**: Determinate Nix
- **System Configuration**: nix-darwin
- **User Configuration**: home-manager (integrated as nix-darwin module)
- **Secrets Management**: sops-nix with Age encryption
- **Secret Storage**: Infisical
- **Formatter**: nixfmt (RFC-166 compliant)
- **GUI Applications**: Homebrew casks

## Migration Notes

### v2.0 Simplification (November 2024)

This configuration was refactored from an 11-file structure to a 4-file structure while maintaining 100% functional equivalence. Key changes:

**Removed Framework Abstraction:**
- Eliminated flake-parts framework in favor of vanilla flake structure
- Removed `flake/` directory (darwin.nix, devshell.nix, tooling.nix, nixpkgs-config.nix)
- All flake outputs now defined directly in `flake.nix`

**Consolidated System Configuration:**
- Merged `darwin/defaults.nix` and `darwin/apps.nix` into `system.nix`
- Removed `darwin/` directory
- Single file for all nix-darwin configuration

**Adopted Declarative Patterns:**
- Git SSH signing now configured via `programs.git.signing` and `home.file`
- Removed imperative activation scripts (setupAllowedSigners, ensureSshDir, etc.)
- Migrated packages to `programs.*` modules where available (git, gh, direnv, zoxide)
- Removed `home-manager.backupFileExtension` setting (fail-fast on collisions)

**Custom Package Integration:**
- Changed from `perSystem.packages` to overlay pattern
- Custom packages now first-class citizens of nixpkgs

**Homebrew Configuration:**
- Changed cleanup from "zap" to "uninstall" for safer behavior
- Maintained declarative tap management

**Benefits:**
- 64% reduction in file count (11 → 4 files)
- Easier to navigate and understand
- No framework-specific knowledge required
- Purely declarative configuration
- Identical system closure (verified)

For detailed migration information, see `.kiro/specs/nix-darwin-simplification/`.

## License

This configuration is personal and provided as-is for reference purposes.
