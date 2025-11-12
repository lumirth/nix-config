# AGENTS.md - AI Assistant Guide for Nix Configuration
## Using MCP-NixOS, Context7, and Tavily Search

## Purpose

This document helps AI assistants (Claude, Cursor, ChatGPT, etc.) understand this Nix configuration and provide accurate, context-aware assistance.

**CRITICAL REQUIREMENT:** You must use the three MCP servers enabled in this environment to answer questions about this configuration:
- **mcp-nixos** – Real-time access to 130K+ packages and 22K+ config options
- **context7** – Current, version-specific documentation
- **tavily** – Latest community solutions and workarounds

Do not guess or hallucinate about Nix. Validate all answers using these tools first.

---

## Repository Overview

**Location:** `/Users/lu/.config/nix/`

**Purpose:** Declarative macOS system configuration using nix-darwin + home-manager + Determinate Nix

**Key Principle:** Everything is declared in configuration files. Imperative commands are avoided.

---

## Architecture

### Three-Tier System

1. **System Tier (nix-darwin)**
   - macOS settings and preferences
   - System-wide services
   - Managed via `darwin-rebuild switch`

2. **Home Tier (home-manager)**
   - CLI tools and packages
   - Shell configuration (zsh, tmux, etc.)
   - Dotfiles and user environment
   - Integrated as a nix-darwin module and applied automatically via `sudo darwin-rebuild switch --flake .#lu-mbp`

3. **Project Tier (devenv)**
   - Per-project development environments
   - Language-specific tools
   - Auto-loaded via direnv
   - Not in this repo (lives in individual projects)

### Technology Stack

- **Nix Distribution:** Determinate Nix (for performance: lazy trees, native Linux builder)
- **System Config:** nix-darwin
- **User Config:** home-manager
- **Nix Settings:** Determinate's nix-darwin module (via `determinate.darwinModules.default`)
- **Formatter:** nixfmt (RFC-166 compliant)
- **Secrets:** sops-nix with Age encryption, YAML format
- **Important:** `nix.enable = false;` because Determinate manages Nix directly

> **CLI note:** Home Manager runs inside nix-darwin, so the single command `sudo darwin-rebuild switch --flake .#lu-mbp` applies both system and user changes atomically.

### Simplified Architecture

This configuration uses a **4-file structure** optimized for single-machine use:

1. **flake.nix** – Entry point with all inputs, outputs, nixpkgs instantiation, overlays, devShell, and checks
2. **system.nix** – Complete nix-darwin configuration (Determinate Nix, Homebrew, macOS defaults, Dock, app preferences)
3. **home.nix** – Complete home-manager configuration (packages, shell, Git, SSH, secrets)
4. **pkgs/claude-code-acp/default.nix** – Custom package definition

**Key Benefits:**
- 64% reduction in file count from previous 11-file structure
- Single source of truth for each concern
- No framework abstractions (vanilla flake structure)
- Declarative-first patterns throughout
- Easier navigation and modification
- Modern Nix best practices throughout

---

## Repository Structure

This configuration uses a simplified 4-file structure optimized for single-machine use:

```
/Users/lu/.config/nix/
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

### Key Files

- **flake.nix** – Vanilla flake structure (no flake-parts) with all inputs, outputs, nixpkgs instantiation with config and overlays, darwinConfigurations, devShells, checks, and treefmt configuration.
- **system.nix** – Complete nix-darwin configuration including Determinate Nix settings, Homebrew casks/brews/MAS apps, macOS system defaults (NSGlobalDomain, Finder, screencapture), Dock configuration, application preferences (CustomUserPreferences), Touch ID configuration with tmux/screen support, and system user settings.
- **home.nix** – Complete home-manager configuration including CLI packages, shell setup (zsh, starship, direnv, zoxide, fzf), declarative Git configuration with SSH signing, SSH configuration, sops secrets management, fonts, and environment variables.
- **pkgs/claude-code-acp/default.nix** – Custom package integrated via overlay pattern in flake.nix, available as `pkgs.claude-code-acp`.

Home Manager is integrated as a nix-darwin module, meaning one `sudo darwin-rebuild switch --flake .#lu-mbp` updates everything atomically.

---

## MCP Server Requirements

### When You MUST Use MCP Servers

**Use mcp-nixos for ANY question about:**
- Package names and existence
- Configuration option names
- nix-darwin and home-manager options
- Nix syntax and expressions
- Module imports and organization

**Use context7 for ANY question about:**
- Current APIs and their correct usage
- Deprecation status
- Version-specific behavior
- Real code examples (not guesses)
- Home Manager or nix-darwin documentation

**Use tavily for ANY question about:**
- Recent issues or workarounds
- macOS compatibility problems
- Nix ecosystem solutions from the past month
- GitHub issues and discussions
- Community best practices

### Workflow for Answering Questions

1. **First:** Query mcp-nixos to validate package names and option syntax
2. **Second:** Query context7 to verify current documentation and APIs
3. **Third:** Query tavily if the user needs workarounds or community solutions
4. **Finally:** Provide the answer based on validated information

**If any MCP server returns "not found" or "unknown," do NOT guess the answer. State explicitly that this does not exist or cannot be validated.**

---

## Common Tasks

### 1. Add a CLI Tool (Permanent Global Installation)

**File to edit:** `home.nix`

**Before you answer:**
- Use mcp-nixos to verify the package name exists
- Use context7 to check for any special configuration needed

**Process:**
1. Edit `/Users/lu/.config/nix/home.nix`
2. Add package to `home.packages` list under `with pkgs;`
3. Run `sudo darwin-rebuild switch --flake /Users/lu/.config/nix#lu-mbp`

**Example structure** (verify details with mcp-nixos):
```nix
# In /Users/lu/.config/nix/home.nix
home.packages = with pkgs; [
  # existing packages
  ripgrep   # <-- verified with mcp-nixos ✓
  fd        # <-- verified with mcp-nixos ✓
];
```

### 2. Add a GUI Application (Homebrew Cask)

**File to edit:** `system.nix` (the `homebrew` block)

**Before you answer:**
- Use mcp-nixos to verify the cask name is correct

**Process:**
1. Edit `/Users/lu/.config/nix/system.nix`
2. Add the cask (or MAS entry) to the corresponding list
3. Run `sudo darwin-rebuild switch --flake /Users/lu/.config/nix#lu-mbp`

**Example structure** (verify details with mcp-nixos):
```nix
# In /Users/lu/.config/nix/system.nix
homebrew = {
  enable = true;
  casks = [
    "raycast"              # <-- verified with mcp-nixos ✓
    "slack"                # <-- verified with mcp-nixos ✓
    "visual-studio-code"   # <-- verified with mcp-nixos ✓
  ];
};
```

### 3. Configure macOS System Settings

**File to edit:** `system.nix`

**Before you answer:**
- Use mcp-nixos to verify all `system.defaults.*` option names
- Use context7 to check for any recent changes in option names

**Process:**
1. Edit `/Users/lu/.config/nix/system.nix`
2. Add settings under `system.defaults.*` (look for the macOS defaults section)
3. Run `sudo darwin-rebuild switch --flake /Users/lu/.config/nix#lu-mbp`

**Important:** All option names must be validated with mcp-nixos. Do not guess at option names.

### 4. Configure Shell (zsh, aliases, prompt)

**File to edit:** `home.nix`

**Before you answer:**
- Use context7 to verify current home-manager shell configuration options
- Use mcp-nixos to verify program names and options

**Process:**
1. Edit `/Users/lu/.config/nix/home.nix`
2. Modify shell programs configuration (look for `programs.zsh`, `programs.starship`, etc.)
3. Run `sudo darwin-rebuild switch --flake /Users/lu/.config/nix#lu-mbp`

**Important:** Shell configuration options change. Use context7 to verify current syntax.

### 5. Update Package Versions

**Command:** `nix flake update`

**Before you answer:**
- Use tavily to check if there are any known breaking changes in the latest nixpkgs
- Use context7 to verify current best practices for updates

**Process:**
```bash
cd /Users/lu/.config/nix
nix flake update
sudo darwin-rebuild switch --flake .#lu-mbp
```

### 6. Authenticate GitHub CLI and Upload SSH Keys

**File:** SSH keys are managed via sops-nix in `home.nix`. The encrypted keys are stored in `secrets/ssh/secrets.yaml` and automatically decrypted to `~/.ssh/` during system build.

**When to run:** After the first `darwin-rebuild switch` (which decrypts and installs the SSH keys), manually authenticate GitHub CLI and upload the keys.

**Process:**
```bash
# Authenticate with GitHub CLI (opens browser)
gh auth login -p https -h github.com -w -s admin:public_key,admin:ssh_signing_key

# Upload SSH key for authentication
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(scutil --get ComputerName) - $(date +%Y-%m-%d)"

# Upload SSH key for commit signing
gh ssh-key add ~/.ssh/id_ed25519.pub --type signing --title "$(scutil --get ComputerName) - Signing - $(date +%Y-%m-%d)"
```

**What this does:**
- Authenticates GitHub CLI with required scopes
- Uploads SSH public key for authentication (git clone, push, etc.)
- Uploads SSH public key for commit signing

For detailed bootstrap procedures, see [docs/BOOTSTRAP.md](docs/BOOTSTRAP.md).

### 7. Fix Configuration Errors

**Before you answer:**
- Use mcp-nixos to validate the configuration syntax
- Use tavily to search for recent issues matching the error
- Use context7 to check for deprecated options

**Never suggest a fix without validating it with these tools first.**

---

## Important Commands

### Applying Configuration Changes

```bash
# Atomic system + home deployment
sudo darwin-rebuild switch --flake /Users/lu/.config/nix#lu-mbp

# Dry runs
darwin-rebuild dry-build --flake /Users/lu/.config/nix#lu-mbp
nix build /Users/lu/.config/nix#darwinConfigurations.lu-mbp.system --no-link

# Validation / formatting
nix flake check        # runs treefmt + builds darwin config
nix fmt                # runs treefmt via the flake formatter
```

### Running Temporary Commands

```bash
# Temporary shell with a package (no installation)
nix shell nixpkgs#PACKAGE_NAME

# Run a package once
nix run nixpkgs#PACKAGE_NAME
```

### Version Control

```bash
# After making changes
cd /Users/lu/.config/nix
git add .
git commit -m "Add ripgrep and fd packages"
git push
```

---

## Commands to NEVER Use

These commands break declarative configuration:

❌ **`nix profile install`** - Conflicts with home-manager
❌ **`nix-env -i`** - Imperative, not declarative
❌ **`nix-env -e`** - Imperative removal
❌ **`nix-env -u`** - Breaks declarative state
❌ **Manual editing of `/etc/nix/nix.conf`** - Use flake instead

Never suggest these commands. Always direct users to edit configuration files instead.

---

## Important Notes for AI Assistants

1. **This system uses Determinate Nix**, not vanilla Nix. Key difference: `nix.enable = false;` in nix-darwin config.

2. **Nix configuration is managed via `determinate-nix.customSettings`** (see `system.nix`), not via nix-darwin's deprecated `nix.*` options.

3. **All configuration lives in `/Users/lu/.config/nix/`**. Do not suggest editing `/etc/nix/` files directly.

4. **One declarative command manages the machine:** `sudo darwin-rebuild switch --flake .#lu-mbp` now rebuilds both system and Home Manager layers atomically.

5. **Imperative package management is forbidden.** Never recommend `nix profile install`, `nix-env -i`, or similar.

6. **For temporary needs, use `nix shell`**, not permanent installation.

7. **GUI apps go through Homebrew casks**, not Nix packages (macOS apps don't work well with Nix).

8. **The config is modular:** Changes usually only require editing one file.

9. **Project environments are separate:** They use devenv in their own directories, not in this config repo.

10. **Version control matters:** Changes should be committed to git for rollback capability.

11. **VALIDATION IS REQUIRED:** Every package name, configuration option, and Nix function must be validated with MCP servers before suggesting it. Do not guess.

12. **Secrets workflow:** Encrypted assets live under `secrets/` via sops-nix in YAML format. The Age private key is provided by Infisical (`SOPS_AGE_KEY` in workspace `f3d4ff0d-b521-4f8a-bd99-d110e70714ac`, env `prod`, path `/macos`). `bin/infisical-bootstrap-sops` wraps `infisical secrets get … --plain --silent` to hydrate `~/.config/sops/age/keys.txt`; run it manually before rebuilding (the devshell prints a warning if the key is missing). SSH auth/signing keys are managed via sops (encrypted in `secrets/ssh/secrets.yaml`), which Home Manager decrypts and copies into `~/.ssh/` before `~/bin/bootstrap-ssh.sh` pushes them to GitHub. Never commit `.infisical.json` or plaintext secrets. See [docs/BOOTSTRAP.md](docs/BOOTSTRAP.md) for detailed procedures.

12. **DO NOT HALLUCINATE:** If an MCP server says something doesn't exist or cannot be validated, it doesn't exist. Say so explicitly.

---

## Package Categories

### Packages for `modules/home/packages.nix` (Nix)

CLI utilities, development tools, language runtimes, system tools.

**Verify with mcp-nixos before suggesting a package name.**

### Packages for `hosts/*/homebrew` blocks (Homebrew)

GUI applications, browsers, macOS-specific apps, anything with a graphical interface.

**Verify with mcp-nixos before suggesting a cask name.**

### Packages for Project `devenv.nix`

Project-specific language versions, project dependencies, development services.

**Verify with context7 for current devenv syntax.**

---

## Troubleshooting

### Configuration Not Applied After Rebuild

**What to do:**
1. Check if `darwin-rebuild switch --flake /Users/lu/.config/nix#lu-mbp` completed without errors
2. Use mcp-nixos to validate configuration syntax
3. Use tavily to search for similar recent issues

### Package Not Found

**What to do:**
1. Use mcp-nixos to search for the exact package name
2. Use tavily to check if there are recent naming changes
3. Try: `nix flake update` to get latest nixpkgs

### "infinite recursion" Error

**What to do:**
1. Use mcp-nixos to validate module syntax
2. Look for circular imports in the modules
3. Use tavily to search for recent "infinite recursion" issues with nix-darwin

### Option Not Found in Configuration

**What to do:**
1. Use mcp-nixos to verify the exact option name
2. Use context7 to check for deprecations or renames
3. Use tavily to search for recent option name changes

---

## Inputs and Dependencies

The `flake.nix` manages:
- **nixpkgs**: Package repository
- **nix-darwin**: macOS system configuration
- **home-manager**: User environment configuration
- **determinate**: Determinate Systems' nix-darwin module

**Updating:**
```bash
cd /Users/lu/.config/nix
nix flake update
darwin-rebuild switch --flake .#lu-mbp
```

**Before suggesting an update, use tavily to check for breaking changes.**

---

## Quick Reference

| Task | File | Use MCP Server |
|------|------|----------------|
| Add CLI tool | `home.nix` | mcp-nixos ✓ |
| Add GUI app | `system.nix` (`homebrew` block) | mcp-nixos ✓ |
| Configure Dock | `system.nix` (Dock section) | mcp-nixos ✓ |
| Configure Finder | `system.nix` (system.defaults section) | mcp-nixos ✓ |
| Configure shell | `home.nix` | context7 ✓ |
| Configure Nix | `system.nix` (determinate-nix section) | mcp-nixos ✓ |
| Configure Touch ID | `system.nix` (security.pam section) | mcp-nixos ✓ |
| Manage secrets | `secrets/ssh/secrets.yaml` | context7 ✓ |
| Find workaround | any | tavily ✓ |
| Update versions | `flake.lock` | tavily ✓ |

---

## Summary

**Every answer about this configuration MUST be validated using MCP servers:**

1. **mcp-nixos** for package/option validation
2. **context7** for current documentation
3. **tavily** for community solutions

**If you cannot validate with these tools, say so. Do not guess about Nix.**

The goal is **accurate, validated assistance** that actually works, not hallucinated answers that waste the user's time.
