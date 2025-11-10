# Comprehensive Nix + macOS Setup Guide: From Frustration to Practicality

## Executive Summary

This guide distills the current state (November 2025) of using Nix on macOS with nix-darwin and home-manager. It acknowledges your real frustrations, explains why they exist, provides practical solutions, and gives you a clear recommended setup.

**TL;DR:** Use Determinate Nix + nix-darwin + home-manager + devenv + Determinate's nix-darwin module, keeping everything in one declarative flake. This is the best balance of performance, UX, and true declarativity.

---

## Part 1: Understanding Your Frustration

### Why Nix Is Hard

**Real, acknowledged problems:**

1. **Documentation is fragmented and outdated**
   - Official docs, nix.dev, NixOS Wiki, community blogs all contradict each other
   - Examples use deprecated commands like `nix-env`
   - Error messages are cryptic and unhelpful

2. **The learning curve is steep (2-3 weeks)**
   - Requires understanding Nix language, flakes, and declarative configuration
   - Other tools teach in 2-3 hours
   - Nix requires investing significant time before seeing benefits

3. **Daily workflows are tedious**
   - Adding a package means: edit file → run rebuild → wait
   - Running one-off commands isn't obvious
   - No built-in command to add packages to home-manager

4. **The tool ecosystem is fragmented**
   - Multiple ways to do the same thing
   - Community can't agree on best practices
   - "Use X or Y depending on your use case" is the most common advice

5. **AI tools can't help effectively**
   - Training data is limited
   - Examples online are outdated or wrong
   - Nix's complexity defeats generic AI assistance

### Why This Happened

The Nix ecosystem grew organically without strong governance. Eelco Dolstra (creator) ran both Nix and Determinate Systems, creating perception of corporate influence. This led to:

- Eelco's 2024 forced resignation over governance concerns
- Creation of Lix as a community-governed alternative
- Determinate Systems (his company) now pushing Determinate Nix
- General distrust and fragmentation in the community

**The upside:** These conflicts forced improvements and alternatives to emerge.

---

## Part 2: The Idiomatic Setup (2025)

### Architecture: Three-Tier Approach

Your configuration lives in three clear layers:

**1. System Tier (nix-darwin)**
- macOS settings and services
- System-wide environment variables
- Managed via `darwin-rebuild switch`

**2. Home Tier (home-manager)**
- CLI tools and utilities
- Shell/dotfile configuration
- User-specific packages
- Managed via `home-manager switch` (or combined with darwin-rebuild)

**3. Project Tier (devenv or flakes)**
- Per-project dependencies
- Language-specific tools
- Automatically loaded via direnv
- Managed via `devenv shell` or `nix develop`

**Single rebuild command applies all three layers:**
```bash
darwin-rebuild switch --flake ~/.config/darwin
```

### Recommended Tech Stack

| Layer | Tool | Why |
|-------|------|-----|
| **Nix Distribution** | Determinate Nix | Best macOS performance (lazy trees 3-20x faster), native Linux builder, better error messages |
| **Installer** | Determinate Systems installer | Best installer experience, survives macOS upgrades, built-in flakes support |
| **System Config** | nix-darwin | Standard, well-maintained, macOS-specific |
| **User Config** | home-manager | De facto standard for dotfiles/packages |
| **Nix Config** | Determinate's nix-darwin module | Declarative Nix settings without `nix.enable = true` |
| **Projects** | devenv + direnv | Better UX than raw flakes, automatic shell loading |
| **Package Discovery** | `nix search nixpkgs#package` | Finding packages without leaving terminal |
| **One-off Commands** | `nix shell nixpkgs#package` | Ephemeral, sandboxed, instant with caching |

### Folder Structure

```
~/.config/darwin/
├── flake.nix              # Main entry point (see below)
├── flake.lock             # Locked dependency versions
├── modules/
│   ├── system.nix         # macOS system settings
│   ├── packages.nix       # CLI tools and packages
│   ├── homebrew.nix       # Homebrew GUI apps
│   └── shell.nix          # Shell configuration (zsh, etc)
└── users/
    └── yourname/
        └── home.nix       # User-specific home-manager config
```

---

## Part 3: Complete Example Configuration

### flake.nix (Everything Centralized)

```nix
{
  description = "macOS configuration with nix-darwin + home-manager + Determinate Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Determinate Nix's nix-darwin module for declarative Nix settings
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, determinate }:
    let
      system = "aarch64-darwin";  # M1/M2/M3 or "x86_64-darwin" for Intel
      username = "yourname";
    in {
      darwinConfigurations."MacBook" = nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          # Add Determinate's module (manages Nix settings declaratively)
          determinate.darwinModules.default

          # Home-manager integration
          home-manager.darwinModules.home-manager

          # Import organized modules
          ./modules/system.nix
          ./modules/packages.nix
          ./modules/homebrew.nix
          ./modules/shell.nix

          # Main configuration
          ({ pkgs, ... }: {
            # Let Determinate handle Nix installation and configuration
            nix.enable = false;

            # Declare Nix settings centrally (managed by Determinate)
            determinate-nix.customSettings = {
              experimental-features = "nix-command flakes";
              trusted-substituters = [
                "https://cache.nixos.org"
                "https://nix-community.cachix.org"
              ];
              trusted-public-keys = [
                "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              ];
              max-jobs = "auto";
              cores = 0;
            };

            # macOS version tracking
            system.stateVersion = 4;

            # Home-manager configuration
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = ./users/${username}/home.nix;
          })
        ];
      };
    };
}
```

### modules/system.nix

```nix
{ pkgs, ... }:

{
  # Keyboard
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;

  # Finder
  system.defaults.finder.AppleShowAllFiles = true;
  system.defaults.finder.ShowPathbar = true;
  system.defaults.finder.ShowStatusBar = true;

  # Dock
  system.defaults.dock.autohide = true;
  system.defaults.dock.minimize-to-application = true;
  system.defaults.dock.mru-spaces = false;

  # Screenshots
  system.defaults.screencapture.location = "/tmp";

  # Other sensible defaults
  system.defaults.NSGlobalDomain.AppleInterfaceStyle = "Dark";
  system.defaults.NSGlobalDomain.KeyRepeat = 2;
}
```

### modules/packages.nix

```nix
{ pkgs, ... }:

{
  # CLI tools available globally
  home-manager.users.yourname = {
    home.packages = with pkgs; [
      # Essential
      git
      curl
      wget

      # Development
      vim
      neovim
      tmux

      # Search/Filter
      ripgrep
      fd
      fzf
      jq

      # Utilities
      htop
      tree
      bat

      # Languages (if used daily)
      nodejs
      python3

      # Add more as needed
    ];
  };
}
```

### modules/homebrew.nix

```nix
{ ... }:

{
  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";

    taps = [
      "homebrew/cask"
      "homebrew/cask-fonts"
    ];

    # Command-line tools (these could go in home.packages instead)
    brews = [
      "cowsay"
    ];

    # GUI applications (must use Homebrew, Nix doesn't manage macOS apps well)
    casks = [
      "raycast"
      "slack"
      "visual-studio-code"
      "kitty"  # or alacritty
      "rectangle"
      "font-jetbrains-mono"
    ];
  };
}
```

### modules/shell.nix

```nix
{ ... }:

{
  home-manager.users.yourname = {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      enableAutosuggestions = true;
      syntaxHighlighting.enable = true;

      shellAliases = {
        ll = "ls -lah";
        gs = "git status";
        gc = "git commit";
        ga = "git add";
      };

      # Your .zshrc contents here
    };

    programs.starship = {
      enable = true;
      # Prompt configuration
    };

    programs.tmux = {
      enable = true;
      # Tmux configuration
    };
  };
}
```

### users/yourname/home.nix

```nix
{ pkgs, ... }:

{
  home.stateVersion = "25.05";

  home.homeDirectory = "/Users/yourname";
  home.username = "yourname";

  # Packages already in modules/packages.nix are inherited

  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "you@example.com";

    extraConfig = {
      pull.rebase = true;
      init.defaultBranch = "main";
    };
  };

  # More user-specific configuration here
}
```

---

## Part 4: Daily Workflow

### Adding a Permanent Package

**Step 1: Edit your config**
```bash
vim ~/.config/darwin/modules/packages.nix
```

**Step 2: Add to home.packages**
```nix
home.packages = with pkgs; [
  # ... existing packages
  ripgrep  # <-- add here
];
```

**Step 3: Apply changes**
```bash
darwin-rebuild switch --flake ~/.config/darwin
```

**To streamline this, create a helper:**
```bash
#!/bin/bash
# ~/.local/bin/nix-add
# Usage: nix-add ripgrep

PACKAGE="$1"
CONFIG_FILE="$HOME/.config/darwin/modules/packages.nix"

# Add package to the list
sed -i '' "/home.packages = with pkgs; \[/a\\
  $PACKAGE" "$CONFIG_FILE"

# Rebuild
darwin-rebuild switch --flake ~/.config/darwin

# Optional: commit to git
cd ~/.config/darwin && git add . && git commit -m "Add $PACKAGE"
```

Make it executable: `chmod +x ~/.local/bin/nix-add`

Now: `nix-add ripgrep` 🎉

### Adding a GUI App (Homebrew)

**Option A: Install directly (quick)**
```bash
brew install raycast
# It works immediately
```

**Option B: Add to config (permanent)**
```bash
# Edit modules/homebrew.nix
vim ~/.config/darwin/modules/homebrew.nix

# Add to casks list
casks = [ "raycast" ];

# Apply
darwin-rebuild switch --flake ~/.config/darwin
```

**Recommendation:** Use Option A for most GUI apps (they're not critical to reproducibility), use Option B for core tools you need everywhere.

### Running One-Off Commands (No Installation)

```bash
# Try a package without installing
nix shell nixpkgs#cowsay -c cowsay "hello"

# Multiple packages
nix shell nixpkgs#{nodejs,python3,postgresql}

# Your shell opens in that environment, type 'exit' to leave
```

**Perfect for:**
- Following tutorials that assume global installs
- Trying tools before committing to them
- Cross-platform commands you use once a month

### Project Development

**Create devenv.nix in your project:**

```nix
# project/devenv.nix
{ pkgs, lib, config, ... }:

{
  languages.python.enable = true;
  languages.python.version = "3.11";

  packages = with pkgs; [
    postgresql
    redis
  ];

  env.DATABASE_URL = "postgresql://localhost/mydb";
  env.PYTHONPATH = ".";

  processes.dev-server.exec = "python -m uvicorn main:app --reload";
}
```

**Enter the environment:**
```bash
cd project
devenv shell
# Your shell is now configured with Python 3.11, PostgreSQL, Redis
# PYTHONPATH is set
# Just start coding

devenv up
# In another terminal, starts the dev server
```

**Automatic loading with direnv:**
```bash
# Create .envrc in project root
echo "use flake . --no-pure-eval" > .envrc
direnv allow
# Now cd'ing into the project automatically loads the environment
```

### Rebuilding After Configuration Changes

```bash
# After editing any module files:
darwin-rebuild switch --flake ~/.config/darwin

# Or if you're in the config directory:
cd ~/.config/darwin
darwin-rebuild switch --flake .

# To see what will change before applying:
darwin-rebuild dry-build --flake .
```

---

## Part 5: Commands to Know (and Avoid)

### Safe Commands (Use These)

| Command | Purpose | Notes |
|---------|---------|-------|
| `nix shell nixpkgs#pkg` | Temporary ephemeral environment | No persistent changes |
| `nix run nixpkgs#pkg` | Run a package once | Disappears after execution |
| `nix develop` | Enter project dev shell | Project-specific |
| `darwin-rebuild switch --flake .` | Apply system config | Your primary rebuild command |
| `home-manager switch` | Apply home-manager config | Already run by darwin-rebuild |
| `nix search nixpkgs#name` | Find packages | Read-only search |
| `nix flake update` | Update flake.lock | Declarative version update |

### Commands to AVOID (These Break Declarativity)

| Command | Why Avoid | Alternative |
|---------|-----------|-------------|
| `nix profile install` | Conflicts with home-manager | Add to `home.packages` in config |
| `nix-env -i` | Imperative, creates drift | Add to `home.packages` |
| `nix-env -e` | Imperatively removes packages | Remove from `home.packages` |
| `nix-env -u` | Breaks declarative state | Run `darwin-rebuild switch` |
| `nix profile remove` | Manual state modification | Only use to fix conflicts |

**Core principle:** If it modifies state, it should go through your config files, not command-line flags.

---

## Part 6: AI-Assisted Configuration Management

### Create AGENTS.md in Your Repo

This file teaches AI (Claude, Cursor, etc.) how to understand your setup:

```markdown
# Nix Configuration Context

## Repository Structure

Your config lives in `~/.config/darwin/`:
- `flake.nix`: Main entry point (system + home-manager + Nix settings)
- `modules/packages.nix`: CLI tools and packages
- `modules/homebrew.nix`: GUI applications
- `modules/system.nix`: macOS settings
- `modules/shell.nix`: Shell configuration
- `users/yourname/home.nix`: User-specific config

## Key Principles

1. **Everything is declarative**: Changes go in config files, not imperative commands
2. **Single rebuild**: `darwin-rebuild switch --flake ~/.config/darwin` applies all changes
3. **Determinate Nix manages Nix**: `nix.enable = false;` in nix-darwin
4. **Version controlled**: Keep ~/.config/darwin in git

## Common Tasks

### Add a CLI Tool
1. Edit `modules/packages.nix`
2. Add to `home.packages` list
3. Run `darwin-rebuild switch --flake ~/.config/darwin`

Example:
```nix
home.packages = with pkgs; [
  # existing packages...
  jq  # <-- add here
];
```

### Add a GUI App (Homebrew)
1. Edit `modules/homebrew.nix`
2. Add to `casks` list
3. Run `darwin-rebuild switch --flake ~/.config/darwin`

Example:
```nix
casks = [
  "existing-apps"
  "raycast"  # <-- add here
];
```

### Run a Command Temporarily
```bash
nix shell nixpkgs#PACKAGE_NAME -c bash
# Type 'exit' when done
```

### Create a New Project Environment
Create `project-name/devenv.nix`:
```nix
{
  languages.python.enable = true;
  languages.python.version = "3.11";
  packages = with pkgs; [ postgresql ];
}
```
Then: `devenv shell`

## Important: Commands to NEVER Use

- ❌ `nix profile install` - breaks home-manager
- ❌ `nix-env -i` - imperative, not declarative
- ❌ Manual editing of `/etc/nix/nix.conf` - use flake instead

## Documentation

- Main config: ~/.config/darwin/flake.nix
- Home-manager: https://nix-community.github.io/home-manager/
- nix-darwin: https://github.com/nix-darwin/nix-darwin
- Determinate Nix: https://determinate.systems/
- devenv: https://devenv.sh
```

**Usage:**
```bash
# In Claude/Cursor, paste:
@repo Let me understand this Nix setup.

# Then ask naturally:
"I want to add jq and fd to my global packages. How do I do that?"
# Claude now gives correct answers because it has context
```

### Create .claude/CLAUDE.md for Project-Specific Help

```markdown
# Development Setup

This project uses devenv for reproducible environments.

## Quick Start
```bash
devenv shell
```

## Stack
- Language: Python 3.11
- Database: PostgreSQL
- Cache: Redis

## Adding Dependencies

### Python packages:
Edit `devenv.nix`:
```nix
languages.python.dependencies = with pkgs; [
  # add here
];
```

### System packages:
Edit `devenv.nix`:
```nix
packages = with pkgs; [
  # add here
];
```

Then: `devenv reload`
```

---

## Part 7: Installer Choice Comparison

### The Situation (November 2025)

Determinate Systems announced they're dropping upstream Nix support from their installer on **January 1, 2026**. This changes the recommendation.

### Comparison

| Installer | Pros | Cons | Status |
|-----------|------|------|--------|
| **Determinate Nix** | Best performance (lazy trees), best macOS integration, native Linux builder | Corporate-controlled, governance concerns, requires `nix.enable = false;` | Recommended if you trust Determinate |
| **Lix** | Community-governed, better error messages, independent infrastructure | Smaller team, no lazy trees (yet), slightly behind on features | Recommended for values-aligned devs |
| **Official Nix Installer** | Most conservative, no corporate influence | Rough macOS experience, breaks on OS updates, slower | Fallback option |

### Recommendation

**Determinate Nix + Determinate's nix-darwin module** for best overall experience:
- Use: `curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate`
- Then in flake: `determinate.darwinModules.default` and `nix.enable = false;`
- This gives you lazy trees (3-20x faster) and native Linux builder

**OR Lix if you prioritize independence:**
- Use: `curl -sSf -L https://install.lix.systems/lix | sh -s -- install`
- No changes to your flake.nix needed
- Community-governed, but no performance advantages yet

---

## Part 8: Addressing Your Original Frustrations

### "Why is adding a package so painful?"

**Root cause:** Nix prioritizes reproducibility over convenience. The "right way" is editing config files.

**Solutions:**
1. **Accept it as the trade-off** for reproducibility
2. **Use the `nix-add` helper script** (15 minutes to write)
3. **Keep a packages.txt file** your config reads from
4. **Use `nix shell` for everything temporary**

### "How do I run tutorials that assume global installs?"

**Solution:** Use `nix shell` for ephemeral environments:
```bash
nix shell nixpkgs#nodejs -c node script.js
```

No global pollution, no permanent changes, works just like the tutorial expects.

### "Why can't AI help me with Nix?"

**Root cause:** Fragmented docs + niche tool = poor training data.

**Solution:** Create AGENTS.md to give AI context. Now it understands your setup and gives correct answers.

### "Is Nix even worth this complexity?"

**For solo developers:** Maybe not. Docker or plain Homebrew might be simpler.

**For teams:**
- Same config across local/CI/production ✅
- Reproducibility that survives months of changes ✅
- Easy onboarding with `darwin-rebuild switch` ✅

**The honest take:** Nix's value is in reproducibility at scale. If you're solo and your setup works, simpler tools are fine. But if managing complexity across machines or time matters, the investment pays off.

### "What about Docker instead?"

| Aspect | Nix | Docker |
|--------|-----|--------|
| Local dev performance | Better (native execution) | Worse (VM overhead on macOS) |
| System configuration | Perfect | Doesn't handle OS config |
| Learning curve | 3 weeks | 3 hours |
| Team adoption | Harder | Easy |
| Setup on new machine | `darwin-rebuild switch` | Manual container setup |
| Reproducibility | 99% | 70% |
| One-off packages | `nix shell` (instant) | `docker pull` (slow) |

**Use Docker if:**
- Team is large and Docker-skilled
- You're already in Kubernetes
- Reproducibility of shell scripts is acceptable

**Use Nix if:**
- Configuration-as-code matters
- You want the same setup everywhere
- You develop cross-platform

---

## Part 9: Complete Step-by-Step Bootstrap

### 1. Install Nix (Choose One)

**Option A: Determinate Nix (Recommended)**
```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
```

**Option B: Lix (Community alternative)**
```bash
curl -sSf -L https://install.lix.systems/lix | sh -s -- install
```

**Option C: Official Nix (Conservative)**
```bash
sh <(curl -L https://nixos.org/nix/install)
```

### 2. Create Configuration Directory

```bash
mkdir -p ~/.config/darwin
cd ~/.config/darwin
git init
```

### 3. Create flake.nix

Copy the example from Part 3 above, replace `yourname` with your username.

### 4. Create Modules

```bash
mkdir -p modules users/yourname
touch modules/{system,packages,homebrew,shell}.nix
touch users/yourname/home.nix
```

Fill each file with the examples from Part 3.

### 5. Build and Switch

```bash
cd ~/.config/darwin

# First build (evaluates config, pulls dependencies)
darwin-rebuild switch --flake .

# You'll see detailed output of what's changing
# If successful, your system is now configured!

# Verify it worked
echo $PATH  # Should show Nix packages
which jq   # Should be in /nix/store
```

### 6. Set Up direnv for Projects (Optional)

```bash
# Install direnv
brew install direnv

# Add to shell config (~/.zshrc)
eval "$(direnv hook zsh)"

# Create .envrc in each project
echo "use flake . --no-pure-eval" > project/.envrc
direnv allow project
```

### 7. Version Control

```bash
cd ~/.config/darwin
git add .
git commit -m "Initial nix-darwin configuration"
```

---

## Part 10: Troubleshooting

### "infinite recursion" Error

**Binary search approach:**
1. Comment out half your modules
2. `darwin-rebuild switch --flake .`
3. If it works, uncomment 1/4 and repeat
4. Find the culprit, fix the module import

### Package Not Found

```bash
# Search for it
nix search nixpkgs#jq

# Use full name
nix shell nixpkgs#jq -c jq --version

# If still not found, it might be a newer package
nix flake update  # Update nixpkgs to latest
```

### Changes Not Applied After Rebuild

```bash
# Verify you ran the right command
cd ~/.config/darwin
darwin-rebuild switch --flake .

# If using home-manager separately
home-manager switch --flake ~/.config/darwin#yourname
```

### Nix Daemon Issues

```bash
# Restart daemon
sudo killall nix-daemon
# It restarts automatically

# Check daemon status
ps aux | grep nix-daemon
```

### Conflicting Packages

Usually because:
1. You used `nix profile install` (DON'T)
2. You have both Homebrew and Nix managing the same package
3. Resolution: Remove from one, rebuild

```bash
# See what's installed via Nix
nix profile list

# Remove conflicting profile
nix profile remove 0  # adjust number as needed
```

---

## Part 11: When NOT to Use Nix

### Nix Might Not Be Worth It If:

1. **Single language team** - `pyenv` or `nvm` are simpler
2. **Simple one-machine setup** - Manual setup + git-tracked dotfiles work fine
3. **Team doesn't invest in learning** - Nix pays off after 3-4 weeks, but requires commitment
4. **Docker is already standardized** - Don't add complexity if it works
5. **You just need package management** - Homebrew or apt-get are simpler

### Alternatives to Consider:

- **Homebrew + shell scripts** - Simplest, widely known
- **Docker** - Better for large teams, container orchestration
- **Ansible** - More general infrastructure tool
- **Mise / ASDF** - Language-specific version managers
- **Just accept manual setup** - Honest, low complexity

---

## Part 12: The Path Forward

### Month 1: Get It Working

1. Install Nix using this guide
2. Set up the basic configuration from Part 3
3. Add your most-used packages to `modules/packages.nix`
4. Get familiar with `darwin-rebuild switch`

### Month 2: Optimize Workflow

1. Create the `nix-add` helper script
2. Set up direnv for projects you use
3. Create AGENTS.md for AI assistance
4. Build 2-3 project devenv configs

### Month 3: Refine and Extend

1. Add more macOS settings to `modules/system.nix`
2. Configure shell more thoroughly
3. Set up cachix for faster rebuilds if needed
4. Consider contributing improvements back to community

### Ongoing:

- Keep `~/.config/darwin` in git
- Commit changes regularly
- Test rebuilds before pushing
- Share config with teammates for reproducibility

---

## Summary: Your Best Setup

**Install:** Determinate Nix
```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
```

**Use this structure:**
- flake.nix (everything)
- modules/packages.nix (CLI tools)
- modules/homebrew.nix (GUI apps)
- modules/system.nix (macOS settings)
- modules/shell.nix (shell config)
- users/yourname/home.nix (user config)

**Single command:** `darwin-rebuild switch --flake ~/.config/darwin`

**Daily workflow:**
- Edit config files when you need changes
- Use `nix shell nixpkgs#package` for one-offs
- Use `nix-add` helper for quick package additions
- Use devenv + direnv for project work

**AI assistance:** Create AGENTS.md, share with Claude/Cursor

**Benefits:**
- Reproducible across machines ✅
- Version controlled ✅
- Declarative (not imperative) ✅
- Performs well on macOS ✅
- All in one flake ✅

This is honest advice after analyzing the current state of the Nix ecosystem. The goal is your productivity, not adherence to Nix ideals.
