# Requirements Document

## Introduction

This specification defines the requirements for modernizing and hardening the Nix-Darwin configuration located at `/Users/lu/.config/nix`. The improvements focus on five key areas: comprehensive validation and formatting, security hardening through idempotent permissions, architectural refactoring to eliminate brittle code patterns, performance optimization via binary caching, and enhanced macOS integration for fonts and GUI applications. These changes will transform the configuration from a functional baseline into an architecturally sound, maintainable, and robust declarative system that follows modern Nix best practices.

## Glossary

- **System**: The Nix-Darwin configuration repository at `/Users/lu/.config/nix`
- **treefmt-nix**: A Nix flake module that provides unified, repository-wide code formatting
- **statix**: A Nix linter that detects anti-patterns and style issues
- **deadnix**: A tool that identifies and removes unused Nix code dependencies
- **Age Key**: The master encryption key used by sops-nix, stored at `~/.config/sops/age/keys.txt`
- **Overlay**: A Nix function that modifies the package set (pkgs)
- **final**: The first argument to an overlay function, representing the complete, fixed-point package set after all overlays are applied
- **prev**: The second argument to an overlay function, representing the package set before the current overlay is applied
- **Cachix**: A binary cache service for Nix that speeds up builds by providing pre-built packages
- **fontconfig**: A Unix library for font discovery and rendering
- **Cocoa**: The native macOS application framework that uses system font paths
- **Home Manager**: A Nix tool for managing user-level configuration and packages
- **nix-darwin**: A Nix tool for managing macOS system-level configuration
- **allowUnfreePredicate**: A Nixpkgs configuration option that explicitly whitelists unfree packages

## Requirements

### Requirement 1: Comprehensive Validation and Formatting

**User Story:** As a configuration maintainer, I want automated validation and formatting integrated into my development workflow, so that all changes are automatically checked for correctness, style compliance, and efficiency before they are committed.

#### Acceptance Criteria

1. WHEN the System builds, THE System SHALL execute treefmt-nix to format all Nix files using nixpkgs-fmt
2. WHEN the System builds, THE System SHALL execute statix to detect Nix anti-patterns and style violations
3. WHEN the System builds, THE System SHALL execute deadnix to identify unused dependencies
4. THE System SHALL provide a `nix flake check` command that runs all validation checks
5. THE System SHALL provide a `nix fmt` command that formats all files in the repository

### Requirement 2: Security Hardening with Idempotent Permissions

**User Story:** As a security-conscious user, I want my Age encryption key to have correct permissions enforced automatically on every system rebuild, so that my secret management remains secure without manual intervention.

#### Acceptance Criteria

1. WHEN Home Manager activates, THE System SHALL verify the existence of the Age Key file at `~/.config/sops/age/keys.txt`
2. IF the Age Key file exists, THEN THE System SHALL set file permissions to 0600 (read/write for owner only)
3. WHEN permissions are enforced, THE System SHALL log a confirmation message
4. THE System SHALL execute this permission enforcement on every `darwin-rebuild switch` operation
5. THE System SHALL not fail activation if the Age Key file does not exist

### Requirement 3: Architectural Refactoring of Overlay Patterns

**User Story:** As a configuration architect, I want all overlays to follow the modern `final: prev:` convention and use the correct argument for each operation, so that the configuration is composable, maintainable, and free from infinite recursion errors.

#### Acceptance Criteria

1. THE System SHALL define all overlays using the `final: prev:` naming convention
2. WHEN an overlay modifies an existing package, THE System SHALL reference the package from the `prev` argument
3. WHEN an overlay defines dependencies or calls `callPackage`, THE System SHALL reference packages from the `final` argument
4. THE System SHALL use `final.callPackage` instead of `prev.callPackage` for all package definitions
5. THE System SHALL pass validation by `nix flake check` without style warnings about overlay argument naming

### Requirement 4: Declarative Dock Configuration Refactoring

**User Story:** As a configuration maintainer, I want the Dock configuration to use direct declarative references instead of imperative logic, so that the code is simpler, more robust, and easier to understand.

#### Acceptance Criteria

1. THE System SHALL remove all imperative `let` blocks that recalculate `primaryUser` or `userHome` in `modules/darwin/dock.nix`
2. THE System SHALL reference `config.system.primaryUser` directly for user-related values
3. THE System SHALL construct file paths using direct string interpolation with `config` values
4. THE System SHALL maintain identical functional behavior to the original implementation
5. THE System SHALL reduce the total lines of code in `modules/darwin/dock.nix`

### Requirement 5: Binary Cache Performance Optimization

**User Story:** As a developer, I want my custom packages to be cached in a binary cache, so that rebuilds and new machine bootstraps are fast and do not require recompiling packages from source.

#### Acceptance Criteria

1. THE System SHALL configure a Cachix binary cache for custom packages
2. THE System SHALL add the cache URL to `determinate-nix.customSettings.trusted-substituters`
3. THE System SHALL add the cache public key to `determinate-nix.customSettings.trusted-public-keys`
4. THE System SHALL document the cache name and setup process in configuration comments
5. WHERE the user has not yet created a Cachix cache, THE System SHALL provide clear instructions for cache creation

### Requirement 6: Granular Unfree Package Management

**User Story:** As a security-conscious user, I want to explicitly whitelist each unfree package I use instead of globally allowing all unfree packages, so that I maintain control over licensing compliance and prevent accidental installation of unapproved software.

#### Acceptance Criteria

1. THE System SHALL replace `allowUnfree = true` with `allowUnfreePredicate` in nixpkgs configuration
2. THE System SHALL define a list of explicitly approved unfree package names
3. THE System SHALL use `builtins.elem` and `lib.getName` to check if a package is in the approved list
4. THE System SHALL define the unfree predicate in a single location and reuse it for all pkgs instantiations
5. THE System SHALL document each approved unfree package with an inline comment explaining why it is needed

### Requirement 7: Dual-World Font Management for macOS

**User Story:** As a macOS user, I want fonts to be available in both terminal applications and native GUI applications, so that my font choices work consistently across all software I use.

#### Acceptance Criteria

1. THE System SHALL install fonts via Home Manager's `home.packages` or `home.fonts` attributes
2. WHEN Home Manager activates on nix-darwin, THE System SHALL symlink fonts to `~/Library/Fonts/HomeManager`
3. THE System SHALL set `fonts.fontconfig.enable = true` in Home Manager configuration
4. THE System SHALL generate fontconfig configuration files for Unix/CLI applications
5. THE System SHALL verify that fonts are accessible to both Cocoa applications and fontconfig-aware applications

### Requirement 8: Automated Storage Management

**User Story:** As a workstation user, I want automatic garbage collection and incremental store optimization, so that my disk space is managed efficiently without causing system slowdowns during periodic maintenance.

#### Acceptance Criteria

1. THE System SHALL enable automatic garbage collection with `nix.gc.automatic = true`
2. THE System SHALL schedule garbage collection to run weekly via `nix.gc.dates = "weekly"`
3. THE System SHALL enable incremental store optimization with `nix.settings.auto-optimise-store = true`
4. THE System SHALL not use `nix.optimise.automatic` to avoid periodic system-locking scans
5. THE System SHALL document the rationale for choosing incremental optimization over periodic optimization

### Requirement 9: Home Manager File Collision Handling

**User Story:** As a user migrating to declarative configuration, I want Home Manager to handle file collisions gracefully by backing up existing files, so that activations succeed without requiring manual file deletion.

#### Acceptance Criteria

1. THE System SHALL set `home-manager.backupFileExtension = "backup"` in the configuration
2. WHEN Home Manager encounters a file collision, THE System SHALL rename the existing file with the `.backup` extension
3. THE System SHALL create the new Home Manager-managed symlink after backing up the conflicting file
4. THE System SHALL complete activation successfully without manual intervention
5. THE System SHALL preserve the original file content in the backup for user review

### Requirement 10: flake-parts Modular Architecture

**User Story:** As a configuration architect, I want overlays and system configurations organized using flake-parts conventions, so that the codebase is modular, maintainable, and follows modern Nix best practices.

#### Acceptance Criteria

1. THE System SHALL define overlays at the top level of flake-parts modules as system-agnostic functions
2. THE System SHALL apply overlays within the `perSystem` block when instantiating the `pkgs` attribute set
3. THE System SHALL separate definition (top-level) from application (perSystem) for all overlays
4. THE System SHALL organize flake outputs using the flake-parts module system
5. THE System SHALL maintain compatibility with the existing `flake-parts.lib.mkFlake` structure
