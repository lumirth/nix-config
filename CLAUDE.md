# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a declarative macOS system configuration using nix-darwin, home-manager, and Determinate Nix. It manages the entire system state through a simplified 4-file structure optimized for single-machine use.

**Location:** `~/.config/nix/`
**Target machine:** `lu-mbp` (Apple Silicon Mac)

## Commands

### Apply Configuration Changes

```bash
# Apply system + home-manager changes atomically (primary command)
sudo darwin-rebuild switch --flake .#lu-mbp

# Preview changes without applying
darwin-rebuild dry-build --flake .#lu-mbp

# Build without activating (creates ./result symlink)
darwin-rebuild build --flake .#lu-mbp
```

### Validation and Formatting

```bash
# Format all Nix files (RFC-166 compliant via nixfmt)
nix fmt

# Run comprehensive checks (formatting + build validation)
nix flake check

# Update all flake inputs
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

### Secrets Management

```bash
# Bootstrap Age key from Infisical (required before first build)
./bin/infisical-bootstrap-sops

# Edit encrypted secrets
nix shell nixpkgs#sops -c sops secrets/ssh/secrets.yaml
```

### Temporary Package Use

```bash
# Preferred: Use comma for quick one-off runs
, cowsay "hello"       # Runs any nixpkgs package instantly
, htop                 # No need to remember full nix run syntax

# Alternative: Explicit nix commands
nix run nixpkgs#cowsay -- "hello"
nix shell nixpkgs#htop

# Aliases for convenience
nr cowsay -- "hello"   # Short for nix run nixpkgs#
ns htop                # Short for nix shell nixpkgs#
nsr ripgrep            # Short for nix search nixpkgs
```

## Installing Packages

### Permanent (Declarative)

| Type | Where | Example |
|------|-------|---------|
| CLI tool | `home.nix` → `home.packages` | `ripgrep`, `jq`, `htop` |
| Node.js tool | `home.nix` → `nodePackages.X` | `nodePackages.prettier` |
| GUI app | `system.nix` → `homebrew.casks` | `"raycast"` |
| Mac App Store | `system.nix` → `homebrew.masApps` | `"Xcode" = 497799835` |

### Temporary (Ad-hoc)

| Method | Command | When to Use |
|--------|---------|-------------|
| comma | `, cowsay "hi"` | **Preferred** - quick one-off |
| nr alias | `nr cowsay -- "hi"` | Alternative to comma |
| nix run | `nix run nixpkgs#cowsay` | Explicit, verbose |
| nix shell | `nix shell nixpkgs#htop` | Need interactive shell with tool |

### Project-local

| Type | Command | Notes |
|------|---------|-------|
| npm deps | `npm install` | Creates node_modules/ |
| pnpm deps | `pnpm install` | Creates node_modules/ (symlinked, disk-efficient) |
| Python deps | `uv pip install` or `pip install` | Use inside venv |

### DON'T USE (not tracked, may break)

- `npm install -g foo` - Not declarative, may conflict
- `pnpm add -g foo` - Not tracked in config
- `pip install foo` (outside venv) - Pollutes global Python

## Architecture

### 4-File Structure

```
~/.config/nix/
├── flake.nix      # Entry point: inputs, outputs, nixpkgs config, overlays, devShell, checks
├── system.nix     # nix-darwin: Homebrew, macOS defaults, Dock, Touch ID, app preferences
├── home.nix       # home-manager: CLI packages, shell, Git, SSH, secrets
├── pkgs/
│   └── claude-code-acp/default.nix  # Custom package (via overlay)
└── secrets/
    └── ssh/secrets.yaml             # YAML-format encrypted secrets (sops-nix)
```

### Configuration Layers

**flake.nix:**
- All flake inputs (nixpkgs, nix-darwin, home-manager, determinate, sops-nix, treefmt-nix)
- Nixpkgs instantiation with unfree package whitelist
- Custom package overlay (`pkgs.claude-code-acp`)
- darwinConfigurations, devShells, checks, formatter outputs
- treefmt configuration (nixfmt, statix, deadnix)

**system.nix:**
- Determinate Nix settings (`determinateNix.customSettings`)
- Build-time assertions (validates config correctness)
- Homebrew casks, brews, and Mac App Store apps
- macOS system defaults (NSGlobalDomain, Finder, screencapture)
- Dock configuration with persistent apps/folders
- Touch ID for sudo with tmux/screen support
- CustomUserPreferences for app-specific settings

**home.nix:**
- CLI tools and development packages
- Shell configuration (zsh with zsh-defer for fast startup, starship prompt)
- Shell integrations (direnv, zoxide, atuin, fzf) - loaded via zsh-defer
- Declarative Git configuration with SSH signing
- SSH keys management via sops-nix
- Fonts (Nerd Fonts + system fonts with fontconfig)
- Environment variables

### Key Design Patterns

1. **Determinate Nix:** The Nix daemon is managed by Determinate Systems. Therefore `nix.enable = false` and Nix settings go in `determinateNix.customSettings`.

2. **Atomic Updates:** Single command `sudo darwin-rebuild switch --flake .#lu-mbp` applies both system and home-manager changes.

3. **Declarative-Only:** All configuration is in files. No imperative commands.

4. **Build-Time Assertions:** `system.nix` contains assertions that catch misconfigurations early.

5. **Overlay Pattern:** Custom packages defined in `pkgs/` are integrated via overlay, making them available as `pkgs.<name>`.

6. **sops-nix for Secrets:** Secrets are Age-encrypted in YAML format. The Age key is stored in Infisical and bootstrapped manually.

## Common Tasks

### Add a CLI Tool

Edit `home.nix`, add to `home.packages`:

```nix
home.packages = with pkgs; [
  # ... existing packages
  your-package-here
];
```

### Add a GUI Application

Edit `system.nix`, add to `homebrew.casks`:

```nix
homebrew.casks = [
  # ... existing casks
  "your-app-here"
];
```

GUI apps should use Homebrew casks, not Nix packages (macOS apps don't work well with Nix).

### Add a Mac App Store App

Edit `system.nix`, add to `homebrew.masApps`:

```nix
homebrew.masApps = {
  "App Name" = 123456789;  # App Store ID
};
```

### Configure macOS System Settings

Edit `system.nix`, modify `system.defaults`:

```nix
system.defaults = {
  NSGlobalDomain = {
    # Global settings
  };
  finder = {
    # Finder settings
  };
  dock = {
    # Dock settings
  };
};
```

### Add Shell Aliases

Edit `home.nix`, modify `programs.zsh.shellAliases`:

```nix
programs.zsh.shellAliases = {
  # ... existing aliases
  myalias = "my-command";
};
```

### Add a Custom Package

1. Create `pkgs/your-package/default.nix`
2. Add to overlay in `flake.nix`:
   ```nix
   customPkgsOverlay = _final: prev: {
     claude-code-acp = prev.callPackage ./pkgs/claude-code-acp { };
     your-package = prev.callPackage ./pkgs/your-package { };
   };
   ```
3. Reference as `pkgs.your-package` in home.nix or system.nix

### Allow an Unfree Package

Edit `flake.nix`, add to `allowUnfreePredicate`:

```nix
nixpkgsConfig = {
  allowUnfreePredicate = pkg:
    builtins.elem (inputs.nixpkgs.lib.getName pkg) [
      # ... existing packages
      "your-unfree-package"
    ];
};
```

## Imperative Commands to NEVER Use

These break declarative configuration:

- `nix profile install` - conflicts with home-manager
- `nix-env -i` / `nix-env -e` / `nix-env -u` - imperative package management
- Manual edits to `/etc/nix/nix.conf` - use flake instead
- `defaults write` for managed settings - use system.defaults instead

## Secrets Workflow

1. **Age Key:** Stored in Infisical, bootstrapped to `~/.config/sops/age/keys.txt`
2. **Bootstrap:** Run `./bin/infisical-bootstrap-sops` before first build
3. **SSH Keys:** Encrypted in `secrets/ssh/secrets.yaml`, decrypted to `~/.ssh/` during activation
4. **Editing:** Use `nix shell nixpkgs#sops -c sops <file>` to edit encrypted files

The devShell prints a warning if the Age key is missing.

## Shell Startup Optimization

The zsh configuration uses `zsh-defer` to defer loading of non-critical plugins until after the first prompt. This significantly improves shell startup time. The following are loaded synchronously (needed immediately):

- starship prompt
- direnv (for project environments)
- mise (for language version management)

The following are deferred:

- zoxide, atuin, fzf
- zsh-autosuggestions, zsh-syntax-highlighting, zsh-history-substring-search

## Git SSH Signing

Git is configured for SSH commit signing:
- Signing key: Managed via sops-nix (path from `sops.secrets.ssh_public_key`)
- Allowed signers file: Generated via `sops.templates` at `~/.config/git/allowed_signers`
- Both signing key upload and authentication key upload to GitHub must be done manually after bootstrap (see docs/BOOTSTRAP.md)

## Flake Inputs

| Input | Purpose |
|-------|---------|
| nixpkgs | Package repository (nixpkgs-unstable) |
| nix-darwin | macOS system configuration |
| home-manager | User environment configuration |
| determinate | Determinate Systems' nix-darwin module |
| nix-homebrew | Declarative Homebrew management |
| homebrew-core | Homebrew core formulae (flake = false) |
| homebrew-cask | Homebrew cask definitions (flake = false) |
| sops-nix | Secrets management with Age encryption |
| treefmt-nix | Multi-formatter configuration |

## Homebrew Behavior

This config manages Homebrew declaratively. Important:

- `brew install X` will be **reverted** on next `darwin-rebuild switch`
- To permanently add a CLI tool: edit `homebrew.brews` in system.nix
- To permanently add a GUI app: edit `homebrew.casks` in system.nix

For temporary testing, use `nix shell nixpkgs#X` instead.

## Project Environment Management

**Architecture: Nix for global, mise for per-project**

Global language runtimes are installed via Nix (home.nix) for stability and system integration. mise is used ONLY for per-project version overrides.

### Global Runtimes (from Nix)

These are already installed via home.nix and available everywhere:
- `node` (v22) - from `nodejs_22`
- `python3` (v3.13) - from `python3`
- `go` - from `go`
- `ruby` (v3.3) - from `ruby_3_3`
- `rustup` / `cargo` - from `rustup`
- `uv` - from `uv`

**Do NOT use `mise use --global` for these.** The Nix versions are properly integrated with macOS and should be your "bedrock."

### Per-Project Overrides (mise)

Use mise ONLY when a project needs a different version than the global Nix default:

```bash
cd ~/project-needing-old-node
mise use node@18        # Creates mise.toml, overrides only in this directory
```

When you `cd` out of the project, you fall back to the stable Nix-installed version.

### Example mise.toml

```toml
[tools]
# Override specific versions for this project only
node = "18.19.0"        # Project needs older Node
python = "3.11"         # Project needs older Python

# Nix backend for system deps (databases, complex tools)
"nix:postgresql" = "16"
"nix:redis" = "7"

[env]
DATABASE_URL = "postgresql://localhost:5432/myapp"
```

Commit `mise.toml` and `mise.lock` to git for reproducibility.

### When to use `nix:` backend

- Databases (postgresql, redis)
- Complex CLI tools with C dependencies (ffmpeg, imagemagick)

### When to use native backend

- When you need a DIFFERENT version than what Nix provides globally
- The native backend downloads prebuilt binaries (fast)

### Legacy: devenv

`devenv` is kept for backward compatibility with existing projects that use `devenv.nix`.
For new projects, prefer mise + docker-compose for services.

See `docs/MISE-EXAMPLE.md` for a complete mise.toml template.

## Troubleshooting

### Build fails with "nix.enable must be false"

Expected behavior. This configuration uses Determinate Nix. The assertion ensures you don't accidentally enable nix-darwin's Nix management.

### Secrets not decrypting

1. Check Age key exists: `ls ~/.config/sops/age/keys.txt`
2. If missing, run: `./bin/infisical-bootstrap-sops`
3. Rebuild: `sudo darwin-rebuild switch --flake .#lu-mbp`

### Package not found

1. Run `nix flake update` to get latest nixpkgs
2. Check exact package name with `nix search nixpkgs#<name>`

### Touch ID not working in tmux

The configuration includes `security.pam.services.sudo_local.reattach = true`. If still not working, rebuild and restart tmux.

### Rollback needed

Use generation rollback for quick recovery:
```bash
darwin-rebuild rollback
```

For more detailed recovery procedures, see `docs/ROLLBACK.md`.

## File Reference

| File | Purpose |
|------|---------|
| `flake.nix` | Flake entry point, inputs, outputs, overlays |
| `system.nix` | nix-darwin system configuration |
| `home.nix` | home-manager user configuration |
| `pkgs/*/default.nix` | Custom package definitions |
| `secrets/ssh/secrets.yaml` | Encrypted SSH keys |
| `secrets/rectangle-pro/*.padl` | Encrypted app licenses |
| `bin/infisical-bootstrap-sops` | Age key bootstrap script |
| `docs/BOOTSTRAP.md` | New machine setup guide |
| `docs/ROLLBACK.md` | Recovery procedures |
