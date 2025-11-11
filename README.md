# lu's nix-darwin configuration

A streamlined, single-machine macOS configuration using Determinate Nix, nix-darwin, home-manager, and sops-nix. This configuration follows modern Nix best practices with a simplified 7-file structure optimized for maintainability.

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

# 3) Bootstrap SSH keys to GitHub
~/bin/bootstrap-ssh.sh
```

For rollback procedures, see [docs/ROLLBACK.md](docs/ROLLBACK.md).

## Architecture

This configuration uses a simplified 7-file structure designed for single-machine use:

```
~/.config/nix/
├── flake.nix                    # Entry point, inputs, outputs
├── flake/
│   ├── nixpkgs-config.nix       # Shared nixpkgs configuration (unfree packages)
│   ├── darwin.nix               # Darwin system output wiring
│   ├── devshell.nix             # Development shell configuration
│   └── tooling.nix              # Formatter and tooling setup
├── system.nix                   # All nix-darwin configuration
├── home.nix                     # All home-manager configuration
├── darwin/
│   ├── defaults.nix             # macOS system.defaults.* settings + Touch ID
│   └── apps.nix                 # Application preferences + Dock configuration
├── pkgs/
│   └── claude-code-acp/         # Custom packages (flake outputs)
│       └── default.nix
└── secrets/
    └── ssh/
        └── secrets.yaml         # YAML-format encrypted secrets
```

### Key Design Principles

1. **Single Machine Optimization**: No unnecessary abstractions for multi-machine deployments
2. **Declarative Integrity**: Pure declarative configuration without imperative commands
3. **Fail-Fast Validation**: Build-time assertions catch configuration errors early
4. **Modern Nix Patterns**: RFC-166 formatting, flake packages over overlays, YAML secrets

### Configuration Layers

**System Layer (system.nix)**
- Determinate Nix configuration (`nix.enable = false`)
- Homebrew casks for GUI applications
- System-wide services and settings
- Imports darwin/defaults.nix and darwin/apps.nix

**Home Layer (home.nix)**
- CLI tools and packages
- Shell configuration (zsh, starship)
- Git, SSH, and development tools
- Secrets management via sops-nix
- Fonts and user applications

**macOS Defaults (darwin/defaults.nix)**
- System preferences (NSGlobalDomain, Finder, etc.)
- Touch ID configuration with tmux/screen support
- Security and authentication settings

**Application Preferences (darwin/apps.nix)**
- Dock configuration
- Application-specific preferences
- Custom user preferences

## Repository Layout

### Core Configuration Files

- **flake.nix** – Flake entry point defining inputs, outputs, and system configuration
- **system.nix** – Complete nix-darwin configuration with Determinate Nix settings
- **home.nix** – Complete home-manager configuration for user environment
- **darwin/defaults.nix** – macOS system defaults and Touch ID configuration
- **darwin/apps.nix** – Application preferences and Dock settings

### Supporting Files

- **flake/nixpkgs-config.nix** – Shared nixpkgs configuration (single source of truth for unfree packages)
- **pkgs/claude-code-acp/** – Custom packages defined as flake outputs
- **secrets/ssh/secrets.yaml** – Encrypted SSH keys in YAML format

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
- Upload to GitHub using `~/bin/bootstrap-ssh.sh`

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

Edit `darwin/defaults.nix` to modify system preferences:

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

## License

This configuration is personal and provided as-is for reference purposes.
