# Design Document

## Overview

This design document outlines the architectural approach for modernizing the Nix-Darwin configuration at `/Users/lu/.config/nix`. The improvements are organized into five major architectural domains: validation infrastructure, security hardening, code quality refactoring, performance optimization, and platform-specific integration. The design maintains backward compatibility while introducing modern best practices from the Nix ecosystem.

The implementation follows a modular, incremental approach where each improvement is self-contained and can be validated independently. The design leverages existing flake-parts infrastructure and introduces new modules that integrate seamlessly with the current architecture.

## Architecture

### High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      flake.nix (Entry Point)                 │
│                    flake-parts.lib.mkFlake                   │
└────────────────────────┬────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
┌────────────────┐ ┌──────────┐ ┌──────────────┐
│ flake/darwin   │ │ flake/   │ │ flake/       │
│ .nix           │ │ tooling  │ │ devshell.nix │
│                │ │ .nix     │ │              │
│ (System Config)│ │ (NEW)    │ │              │
└────────────────┘ └──────────┘ └──────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
┌────────────────┐ ┌──────────┐ ┌──────────────┐
│ treefmt-nix    │ │ statix   │ │ deadnix      │
│ (Formatting)   │ │ (Linting)│ │ (Dead Code)  │
└────────────────┘ └──────────┘ └──────────────┘
```

### Module Organization

The design introduces new modules and refactors existing ones:

```
.
├── flake.nix                          # Updated: overlay definitions, nixpkgs config
├── flake/
│   ├── tooling.nix                    # REFACTORED: treefmt-nix integration
│   ├── darwin.nix                     # Unchanged
│   └── devshell.nix                   # Unchanged
├── modules/
│   ├── system.nix                     # UPDATED: storage management, cachix
│   ├── darwin/
│   │   ├── dock.nix                   # REFACTORED: remove imperative logic
│   │   └── ...                        # Unchanged
│   └── home/
│       ├── sops.nix                   # UPDATED: Age key permissions
│       ├── fonts.nix                  # UPDATED: dual-world font support
│       └── ...                        # Unchanged
└── overlays/
    └── default.nix                    # REFACTORED: final/prev convention
```

## Components and Interfaces

### Component 1: Validation and Formatting Infrastructure

**Purpose:** Provide comprehensive, automated validation of all Nix code through formatting, linting, and dead code detection.

**Implementation Strategy:**

The validation infrastructure is built on treefmt-nix's flake-parts module, which provides a declarative interface for configuring multiple formatters and automatically wires them into `nix fmt` and `nix flake check`.

**File: `flake/tooling.nix`**

```nix
{ self, inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem = { config, pkgs, ... }: {
    # treefmt-nix configuration
    treefmt = {
      projectRootFile = "flake.nix";
      
      # Nix formatting with nixpkgs-fmt
      programs.nixpkgs-fmt.enable = true;
      
      # Linting for anti-patterns
      programs.statix.enable = true;
      
      # Dead code detection
      programs.deadnix.enable = true;
      
      # Global exclusions
      settings.global.excludes = [
        "*.lock"
        ".git/*"
        "result"
        "result-*"
      ];
    };

    # Keep existing darwin build check
    checks = {
      darwin-lu-mbp = pkgs.runCommand "darwin-lu-mbp-check" { } ''
        export HOME=$TMPDIR
        ${pkgs.nix}/bin/nix build ${self}#darwinConfigurations.lu-mbp.system --no-link --print-out-paths
        touch $out
      '';
      
      # treefmt-nix automatically adds:
      # - treefmt = formatting check
    };
  };
}
```

**Interface:**
- **Input:** Nix source files in the repository
- **Output:** 
  - `nix fmt` - Formats all files
  - `nix flake check` - Validates formatting, runs statix, deadnix, and build checks
- **Dependencies:** treefmt-nix flake input (already present)

**Design Rationale:**

The treefmt-nix flakeModule approach is superior to manual configuration because:
1. It automatically sets `formatter.${system}` for `nix fmt`
2. It automatically adds checks for `nix flake check`
3. It handles cross-platform differences (aarch64-darwin)
4. It provides a unified configuration interface for all formatters

### Component 2: Security Hardening - Idempotent Age Key Permissions

**Purpose:** Automatically enforce correct permissions on the sops-nix Age key file on every system activation.

**Implementation Strategy:**

Use Home Manager's activation script system to check and fix permissions. The activation runs after files are provisioned but before the system is considered "active."

**File: `modules/home/sops.nix`**

```nix
{ config, lib, inputs, ... }:
let
  ageKeyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
in
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  sops = {
    age.keyFile = ageKeyFile;
    defaultSopsFile = ../../secrets/secrets.yaml;
    # ... existing sops configuration
  };

  # Idempotent permission enforcement
  home.activation.sopsAgeKeyPermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -f "${ageKeyFile}" ]; then
      run chmod 600 "${ageKeyFile}"
      $DRY_RUN_CMD echo "✓ Enforced 0600 permissions on Age key: ${ageKeyFile}"
    else
      $DRY_RUN_CMD echo "⚠ Age key not found (run bin/infisical-bootstrap-sops first): ${ageKeyFile}"
    fi
  '';
}
```

**Interface:**
- **Input:** Age key file at `~/.config/sops/age/keys.txt`
- **Output:** File permissions set to 0600, log message
- **Trigger:** Every `darwin-rebuild switch` execution
- **Dependencies:** Home Manager activation system

**Design Rationale:**

Using `lib.hm.dag.entryAfter [ "writeBoundary" ]` ensures this runs after Home Manager has written all files but before the activation is complete. The `run` command respects dry-run mode. The script is idempotent - it can run multiple times safely.

### Component 3: Overlay Architecture Refactoring

**Purpose:** Modernize overlay syntax and ensure correct usage of `final` vs `prev` arguments for composability.

**Implementation Strategy:**

Refactor the existing overlay in `overlays/default.nix` to use the modern `final: prev:` convention and apply the correct argument usage rules.

**File: `overlays/default.nix`**

```nix
# Modern overlay using final: prev: convention
final: prev: {
  # Custom package: use final.callPackage and final for dependencies
  claude-code-acp = final.callPackage (
    { buildNpmPackage, fetchFromGitHub, lib }:
    buildNpmPackage rec {
      pname = "claude-code-acp";
      version = "0.10.0";

      src = fetchFromGitHub {
        owner = "zed-industries";
        repo = "claude-code-acp";
        rev = "84b5744a2f458d22839521abf82925cad64f3617";
        hash = "sha256-ZbCumFZyGFoNBNK6PC56oauuN2Wco3rlR80/1rBPORk=";
      };

      npmDepsHash = "sha256-nzP2cMYKoe4S9goIbJ+ocg8bZPY/uCTOm0bLbn4m6Mw=";

      meta = with lib; {
        description = "Zed Claude Code assistant CLI";
        homepage = "https://github.com/zed-industries/claude-code-acp";
        license = licenses.asl20;
        mainProgram = "claude-code-acp";
        maintainers = [ ];
      };
    }
  ) { };
}
```

**Key Changes:**
1. Changed `final: prev:` from implicit to explicit
2. Used `final.callPackage` instead of `prev.buildNpmPackage`
3. Extracted package definition into a separate function for clarity

**Design Rationale:**

- **final.callPackage:** Ensures we use the final version of callPackage (in case another overlay modifies it)
- **Explicit function:** Makes dependencies clear and allows callPackage to auto-inject them
- **Composability:** If another overlay modifies buildNpmPackage or fetchFromGitHub, this package will automatically use those modifications

### Component 4: Declarative Dock Configuration

**Purpose:** Eliminate imperative logic in dock configuration by using direct config references.

**Implementation Strategy:**

Replace the `let` block that recalculates `primaryUser` and `userHome` with direct references to `config.system.primaryUser` and `config.users.users.${config.system.primaryUser}.home`.

**File: `modules/darwin/dock.nix`**

**Before (Imperative):**
```nix
{ config, lib, ... }:
let
  # Brittle: recalculating values that already exist in config
  primaryUser = config.system.primaryUser or "lu";
  userHome = config.users.users.${primaryUser}.home or "/Users/${primaryUser}";
in
{
  system.defaults.dock = {
    persistent-others = [
      "${userHome}/Downloads"
    ];
  };
}
```

**After (Declarative):**
```nix
{ config, lib, ... }:
{
  system.defaults.dock = {
    # Direct reference to config values - no recalculation needed
    persistent-others = [
      "${config.users.users.${config.system.primaryUser}.home}/Downloads"
    ];
    # ... other dock settings
  };
}
```

**Design Rationale:**

The module system guarantees that `config.system.primaryUser` and `config.users.users.<user>.home` are available and correct. Recalculating them with `or` fallbacks suggests these values might be missing, which they never are in a properly configured system. Direct references are:
1. More declarative (no imperative logic)
2. More robust (no fallback logic that could mask errors)
3. Simpler (fewer lines of code)
4. More maintainable (clear data flow)

### Component 5: Binary Cache Configuration

**Purpose:** Configure Cachix binary cache for custom packages to speed up builds.

**Implementation Strategy:**

Add Cachix cache configuration to `modules/system.nix` in the `determinate-nix.customSettings` block.

**File: `modules/system.nix`**

```nix
{ pkgs, ... }:
{
  # ... existing imports ...

  nix.enable = false;

  determinate-nix.customSettings = {
    "experimental-features" = "nix-command flakes";
    "trusted-users" = "root lu";
    
    # Binary caches: NixOS official + nix-community + personal cache
    "trusted-substituters" = lib.concatStringsSep " " [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://lu-nix-config.cachix.org"  # Personal cache for custom packages
    ];
    
    "trusted-public-keys" = lib.concatStringsSep " " [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      # Add your Cachix public key here after creating the cache:
      # "lu-nix-config.cachix.org-1:<YOUR_PUBLIC_KEY>"
    ];
    
    "max-jobs" = "auto";
    "cores" = "0";
  };

  # ... rest of configuration ...
}
```

**Setup Instructions (to be documented in comments):**

```bash
# 1. Create a free Cachix cache at https://app.cachix.org
# 2. Install cachix CLI (already in packages.nix)
# 3. Authenticate: cachix authtoken <YOUR_TOKEN>
# 4. Push custom packages: cachix push lu-nix-config $(nix build .#claude-code-acp --print-out-paths)
# 5. Add the public key to trusted-public-keys above
```

**Design Rationale:**

Cachix is the de facto standard for personal Nix binary caches. It's free for public caches and provides excellent performance. The cache will primarily benefit:
1. Custom overlays (claude-code-acp)
2. New machine bootstraps
3. CI/CD pipelines (if added later)

### Component 6: Granular Unfree Package Management

**Purpose:** Replace global `allowUnfree = true` with explicit per-package whitelisting.

**Implementation Strategy:**

Define a reusable nixpkgs configuration at the top level of `flake.nix` and apply it to all pkgs instantiations.

**File: `flake.nix`**

```nix
{
  # ... inputs ...

  outputs = inputs@{ self, flake-parts, ... }:
    let
      # Centralized nixpkgs configuration
      nixpkgsConfig = {
        # Explicit unfree package whitelist
        allowUnfreePredicate = pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) [
          # GUI Applications (via Homebrew)
          "slack"              # Team communication
          "obsidian"           # Note-taking
          "vscode"             # Code editor
          
          # CLI Tools (if any unfree packages are needed)
          # Add here as needed with justification comments
        ];
      };
    in
    flake-parts.lib.mkFlake
      {
        inherit inputs;
        specialArgs = { inherit self; };
      }
      {
        systems = [ "aarch64-darwin" ];

        perSystem = { system, ... }: {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
            config = nixpkgsConfig;  # Apply centralized config
          };
        };

        # ... rest of flake ...
      };
}
```

**Design Rationale:**

This approach provides:
1. **Security:** Prevents accidental installation of unapproved unfree software
2. **Documentation:** The whitelist serves as documentation of licensing decisions
3. **Maintainability:** Single source of truth for unfree packages
4. **Auditability:** Easy to review what unfree software is approved

### Component 7: Dual-World Font Management

**Purpose:** Make fonts available to both Cocoa (native macOS) and fontconfig (Unix/CLI) applications.

**Implementation Strategy:**

Leverage Home Manager's automatic font linking for macOS and enable fontconfig for CLI applications.

**File: `modules/home/fonts.nix`**

```nix
{ pkgs, ... }:
{
  # Fonts installed via Home Manager are automatically:
  # 1. Symlinked to ~/Library/Fonts/HomeManager (for Cocoa apps)
  # 2. Made available to fontconfig (when enabled below)
  
  home.packages = with pkgs; [
    # Nerd Fonts for terminal and coding
    (nerdfonts.override {
      fonts = [
        "JetBrainsMono"
        "FiraCode"
        "Hack"
      ];
    })
    
    # System fonts
    inter
    source-sans-pro
    source-serif-pro
  ];

  # Enable fontconfig for Unix/CLI applications
  # This generates ~/.config/fontconfig/fonts.conf
  fonts.fontconfig.enable = true;
}
```

**Architecture Diagram:**

```
┌─────────────────────────────────────────────────────┐
│           home.packages (Font Derivations)          │
└────────────────────┬────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌──────────────────────┐
│ Home Manager    │    │ fonts.fontconfig     │
│ (nix-darwin)    │    │ .enable = true       │
│                 │    │                      │
│ Symlinks to:    │    │ Generates:           │
│ ~/Library/Fonts/│    │ ~/.config/fontconfig/│
│ HomeManager     │    │ fonts.conf           │
└────────┬────────┘    └──────────┬───────────┘
         │                        │
         ▼                        ▼
┌─────────────────┐    ┌──────────────────────┐
│ Cocoa Apps      │    │ fontconfig Apps      │
│ (Safari, VSCode,│    │ (Terminal, Emacs,    │
│  Finder, etc.)  │    │  CLI tools, etc.)    │
└─────────────────┘    └──────────────────────┘
```

**Design Rationale:**

macOS has two separate font systems. Home Manager on nix-darwin automatically handles the Cocoa side by symlinking fonts. We must explicitly enable fontconfig for the Unix side. This dual approach ensures fonts work everywhere.

### Component 8: Storage Management

**Purpose:** Automate garbage collection and store optimization without causing system slowdowns.

**Implementation Strategy:**

Enable weekly garbage collection and incremental store optimization.

**File: `modules/system.nix`**

```nix
{ pkgs, lib, ... }:
{
  # ... existing configuration ...

  # Automatic garbage collection
  # Removes old generations and unreferenced store paths
  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 0;  # Sunday
      Hour = 2;     # 2 AM
      Minute = 0;
    };
    options = "--delete-older-than 30d";
  };

  # Incremental store optimization
  # Deduplicates files in /nix/store as they're added
  # This is MUCH better for interactive workstations than nix.optimise.automatic
  # because it spreads the I/O cost across builds instead of doing
  # a massive scan that locks up the system periodically
  nix.settings.auto-optimise-store = true;

  # ... rest of configuration ...
}
```

**Design Rationale:**

- **Weekly GC:** Balances disk space management with keeping recent builds cached
- **30-day retention:** Allows rollback to recent configurations while cleaning old ones
- **Incremental optimization:** Adds ~1-2% overhead to each build but eliminates the periodic multi-hour system-locking scan that `nix.optimise.automatic` would cause
- **Sunday 2 AM:** Runs during typical low-usage time

### Component 9: File Collision Handling

**Purpose:** Allow Home Manager activations to succeed even when conflicting files exist.

**Implementation Strategy:**

Configure Home Manager to backup conflicting files instead of failing.

**File: `flake/darwin.nix` (or wherever home-manager is configured)**

```nix
{
  # ... existing configuration ...

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    
    # Handle file collisions gracefully
    # When HM tries to create a symlink but a file already exists,
    # rename the existing file with .backup extension instead of failing
    backupFileExtension = "backup";
    
    users.lu = import ../hosts/lu-mbp/home;
  };
}
```

**Design Rationale:**

This is essential for:
1. **Initial migration:** When moving from imperative to declarative config
2. **Conflict resolution:** When multiple tools try to manage the same file
3. **Safety:** Original files are preserved, not deleted
4. **Idempotency:** Subsequent runs won't fail on the same conflict

## Data Models

### Nixpkgs Configuration Schema

```nix
{
  allowUnfreePredicate = pkg: bool;
  # Function that takes a package and returns whether it's allowed
  # Used instead of allowUnfree = true for granular control
}
```

### treefmt Configuration Schema

```nix
{
  projectRootFile = "flake.nix";  # File that marks project root
  
  programs = {
    <formatter-name> = {
      enable = bool;
      package = derivation;  # Optional: override default package
      settings = attrset;    # Optional: formatter-specific settings
    };
  };
  
  settings = {
    global.excludes = [ string ];  # Patterns to exclude from all formatters
    formatter.<name> = {
      includes = [ string ];       # Patterns to include
      excludes = [ string ];       # Patterns to exclude
      options = [ string ];        # CLI options
    };
  };
}
```

### Home Manager Activation Script Schema

```nix
{
  home.activation.<name> = lib.hm.dag.entryAfter [ dependencies ] ''
    # Bash script
    # Available commands:
    # - run: Execute command (respects dry-run)
    # - $DRY_RUN_CMD: Prefix for dry-run-aware commands
  '';
}
```

## Error Handling

### Validation Errors

**Scenario:** `nix flake check` fails due to formatting or linting issues

**Handling:**
1. Run `nix fmt` to auto-fix formatting issues
2. Review statix warnings and fix manually
3. Review deadnix output and remove unused code
4. Re-run `nix flake check`

**User Feedback:**
```
error: builder for '/nix/store/...-treefmt-check' failed
  
  Formatting issues found. Run 'nix fmt' to fix automatically.
  
  statix warnings:
    modules/darwin/dock.nix:5:3: Unused binding 'oldValue'
  
  deadnix warnings:
    overlays/default.nix:12: Unused argument 'lib'
```

### Age Key Permission Errors

**Scenario:** Age key file doesn't exist or has wrong permissions

**Handling:**
1. Activation script checks for file existence
2. If missing: logs warning, continues (non-fatal)
3. If present: fixes permissions, logs success

**User Feedback:**
```
⚠ Age key not found (run bin/infisical-bootstrap-sops first): /Users/lu/.config/sops/age/keys.txt
```

or

```
✓ Enforced 0600 permissions on Age key: /Users/lu/.config/sops/age/keys.txt
```

### Unfree Package Rejection

**Scenario:** User tries to install an unfree package not in the whitelist

**Handling:**
Nix evaluation fails with clear error message

**User Feedback:**
```
error: Package 'some-unfree-package' has an unfree license, refusing to evaluate.

You can add this package to the allowUnfreePredicate in flake.nix:

  allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    # ... existing packages ...
    "some-unfree-package"  # Add this
  ];
```

### Binary Cache Failures

**Scenario:** Cachix cache is not accessible or not configured

**Handling:**
Nix falls back to building from source

**User Feedback:**
```
warning: unable to download 'https://lu-nix-config.cachix.org/...': HTTP error 404
falling back to building from source
```

**Resolution:** Non-fatal; builds will just be slower

## Testing Strategy

### Unit Testing (Per-Component)

Each component can be tested independently:

1. **Validation Infrastructure**
   ```bash
   # Test formatting
   nix fmt
   git diff --exit-code  # Should show no changes if already formatted
   
   # Test checks
   nix flake check
   ```

2. **Age Key Permissions**
   ```bash
   # Create test key with wrong permissions
   mkdir -p ~/.config/sops/age
   touch ~/.config/sops/age/keys.txt
   chmod 644 ~/.config/sops/age/keys.txt
   
   # Run activation
   darwin-rebuild switch --flake .#lu-mbp
   
   # Verify permissions were fixed
   stat -f "%Lp" ~/.config/sops/age/keys.txt  # Should output: 600
   ```

3. **Overlay Refactoring**
   ```bash
   # Verify package still builds
   nix build .#claude-code-acp
   
   # Verify no infinite recursion
   nix flake check
   ```

4. **Unfree Package Management**
   ```bash
   # Test that whitelisted packages work
   nix build .#darwinConfigurations.lu-mbp.system
   
   # Test that non-whitelisted packages fail
   # (Add a test package temporarily and verify it's rejected)
   ```

5. **Font Management**
   ```bash
   # Verify fonts are linked
   ls -la ~/Library/Fonts/HomeManager/
   
   # Verify fontconfig is configured
   fc-list | grep -i "JetBrains"
   ```

### Integration Testing

Test the complete system after all changes:

```bash
# 1. Clean build from scratch
nix build .#darwinConfigurations.lu-mbp.system

# 2. Full system activation
sudo darwin-rebuild switch --flake .#lu-mbp

# 3. Verify all checks pass
nix flake check

# 4. Verify formatting is correct
nix fmt
git diff --exit-code

# 5. Test rollback capability
sudo darwin-rebuild switch --rollback
sudo darwin-rebuild switch --flake .#lu-mbp
```

### Validation Checklist

- [ ] `nix flake check` passes
- [ ] `nix fmt` produces no changes
- [ ] `darwin-rebuild switch` succeeds
- [ ] Age key has 0600 permissions
- [ ] Fonts appear in both GUI and terminal apps
- [ ] Custom packages build successfully
- [ ] Unfree packages are explicitly whitelisted
- [ ] Storage management is configured
- [ ] File collisions are handled gracefully
- [ ] All existing functionality still works

## Dependencies

### External Dependencies

- **treefmt-nix:** Already in flake inputs
- **statix:** Provided by nixpkgs (0.5.8)
- **deadnix:** Provided by nixpkgs (1.3.1)
- **cachix:** Already in packages (CLI tool)

### Internal Dependencies

- **flake-parts:** Already in use
- **home-manager:** Already in use
- **nix-darwin:** Already in use
- **sops-nix:** Already in use

### New Dependencies

None - all required tools are already available in nixpkgs or existing flake inputs.

## Migration Path

### Phase 1: Validation Infrastructure (Low Risk)
1. Update `flake/tooling.nix` with treefmt-nix
2. Run `nix fmt` to format existing code
3. Fix any statix/deadnix warnings
4. Verify `nix flake check` passes

### Phase 2: Security and Configuration (Low Risk)
1. Add Age key permission enforcement
2. Add file collision handling
3. Update font configuration
4. Test activation

### Phase 3: Code Quality (Medium Risk)
1. Refactor overlays to use final/prev correctly
2. Refactor dock.nix to remove imperative logic
3. Test builds

### Phase 4: Performance and Policy (Low Risk)
1. Add unfree package whitelist
2. Configure storage management
3. Add Cachix configuration (optional)
4. Test complete system

Each phase can be committed and tested independently, allowing for incremental rollout and easy rollback if issues arise.
