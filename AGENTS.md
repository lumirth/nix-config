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
- **Important:** `nix.enable = false;` because Determinate manages Nix directly

> **CLI note:** Home Manager runs inside nix-darwin, so the single command `sudo darwin-rebuild switch --flake .#lu-mbp` applies both system and user changes atomically.

---

## Repository Structure

```
/Users/lu/.config/nix/
├── flake.nix                    # flake-parts entry point
├── flake/                       # per-system pkgs, devshell, checks, output wiring
├── overlays/                    # custom package overlays (e.g. claude-code-acp)
├── hosts/
│   └── lu-mbp/
│       ├── system/              # nix-darwin host module (imports modules/system.nix)
│       └── home/                # host-scoped home-manager entrypoint
├── modules/
│   ├── system.nix               # Determinate config + shared macOS defaults
│   ├── darwin/                  # system.defaults.*, Dock, Touch ID, app prefs
│   └── home/                    # home-manager modules (packages, shell, git, ssh…)
├── secrets/                     # sops-encrypted blobs (Rectangle Pro licenses, etc.)
└── bin/infisical-bootstrap-sops # fetches Age key from Infisical into ~/.config/sops/age/keys.txt
```

`modules/home/` contains:
- `packages.nix` – complete CLI + font set (referenced by other modules)
- `shell.nix`, `git.nix`, `ssh.nix`, `fonts.nix`, `apps/…` – single-responsibility modules imported by `hosts/lu-mbp/home/default.nix`

`hosts/lu-mbp/system/default.nix` wires nix-darwin + nix-homebrew and imports shared modules. Home Manager is imported as a nix-darwin module, meaning one `sudo darwin-rebuild switch --flake .#lu-mbp` updates everything.

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

**File to edit:** `modules/home/packages.nix`

**Before you answer:**
- Use mcp-nixos to verify the package name exists
- Use context7 to check for any special configuration needed

**Process:**
1. Edit `/Users/lu/.config/nix/modules/home/packages.nix`
2. Add package to `home.packages` list under `with pkgs;`
3. Run `sudo darwin-rebuild switch --flake /Users/lu/.config/nix#lu-mbp`

**Example structure** (verify details with mcp-nixos):
```nix
# In /Users/lu/.config/nix/modules/home/packages.nix
home.packages = with pkgs; [
  # existing packages
  ripgrep   # <-- verified with mcp-nixos ✓
  fd        # <-- verified with mcp-nixos ✓
];
```

### 2. Add a GUI Application (Homebrew Cask)

**File to edit:** `hosts/lu-mbp/system/default.nix` (the `homebrew` block)

**Before you answer:**
- Use mcp-nixos to verify the cask name is correct

**Process:**
1. Edit `/Users/lu/.config/nix/hosts/lu-mbp/system/default.nix`
2. Add the cask (or MAS entry) to the corresponding list
3. Run `darwin-rebuild switch --flake /Users/lu/.config/nix#lu-mbp`

**Example structure** (verify details with mcp-nixos):
```nix
# In /Users/lu/.config/nix/hosts/lu-mbp/system/default.nix
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

**File to edit:** `modules/system.nix`

**Before you answer:**
- Use mcp-nixos to verify all `system.defaults.*` option names
- Use context7 to check for any recent changes in option names

**Process:**
1. Edit `/Users/lu/.config/nix/modules/system.nix`
2. Add settings under `system.defaults.*`
3. Run `darwin-rebuild switch --flake /Users/lu/.config/nix#lu-mbp`

**Important:** All option names must be validated with mcp-nixos. Do not guess at option names.

### 4. Configure Shell (zsh, aliases, prompt)

**File to edit:** `modules/home/shell.nix`

**Before you answer:**
- Use context7 to verify current home-manager shell configuration options
- Use mcp-nixos to verify program names and options

**Process:**
1. Edit `/Users/lu/.config/nix/modules/home/shell.nix`
2. Modify shell programs configuration
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

### 6. Bootstrap SSH + GitHub (when needed)

**File/script:** `modules/home/ssh.nix` auto-generates `~/.ssh/id_ed25519` via `home.activation.setupSSH`; `~/bin/bootstrap-ssh.sh` handles the GitHub upload.

**When to run:** After the first `darwin-rebuild switch` (which creates the key and prints `ssh-add --apple-use-keychain ~/.ssh/id_ed25519`), run the helper to wire the key into GitHub.

**Process:**
```bash
~/bin/bootstrap-ssh.sh
```

The script:
- Uses `gh auth login` (browser-based) if the CLI lacks scopes
- Uploads both auth and signing keys to GitHub

Document any deviations or additional scopes in your change summary so future assistants know what to expect.

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

2. **Nix configuration is managed via `determinate-nix.customSettings`** (see `modules/system.nix`), not via nix-darwin's deprecated `nix.*` options.

3. **All configuration lives in `/Users/lu/.config/nix/`**. Do not suggest editing `/etc/nix/` files directly.

4. **One declarative command manages the machine:** `sudo darwin-rebuild switch --flake .#lu-mbp` now rebuilds both system and Home Manager layers atomically.

5. **Imperative package management is forbidden.** Never recommend `nix profile install`, `nix-env -i`, or similar.

6. **For temporary needs, use `nix shell`**, not permanent installation.

7. **GUI apps go through Homebrew casks**, not Nix packages (macOS apps don't work well with Nix).

8. **The config is modular:** Changes usually only require editing one file.

9. **Project environments are separate:** They use devenv in their own directories, not in this config repo.

10. **Version control matters:** Changes should be committed to git for rollback capability.

11. **VALIDATION IS REQUIRED:** Every package name, configuration option, and Nix function must be validated with MCP servers before suggesting it. Do not guess.

12. **Secrets workflow:** Encrypted assets live under `secrets/` via sops-nix. The Age private key is provided by Infisical (`SOPS_AGE_KEY` in workspace `f3d4ff0d-b521-4f8a-bd99-d110e70714ac`, env `prod`, path `/macos`). `bin/infisical-bootstrap-sops` wraps `infisical secrets get … --plain --silent` to hydrate `~/.config/sops/age/keys.txt`; run it manually before rebuilding (the devshell prints a warning if the key is missing). SSH auth/signing keys are also managed via sops (encrypted files in `secrets/ssh/{id_ed25519,id_ed25519.pub}`), which Home Manager copies into `~/.ssh/` before `~/bin/bootstrap-ssh.sh` pushes them to GitHub. Never commit `.infisical.json` or plaintext secrets.

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
| Add CLI tool | `modules/home/packages.nix` | mcp-nixos ✓ |
| Add GUI app | `hosts/lu-mbp/system/default.nix` (`homebrew` block) | mcp-nixos ✓ |
| Configure Dock | `modules/system.nix` | mcp-nixos ✓ |
| Configure Finder | `modules/system.nix` | mcp-nixos ✓ |
| Configure shell | `modules/home/shell.nix` | context7 ✓ |
| Configure Nix | `flake.nix` | mcp-nixos ✓ |
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
