# Implementation Plan

- [x] 1. Set up validation infrastructure with treefmt-nix
  - Integrate treefmt-nix flakeModule into flake/tooling.nix
  - Configure nixpkgs-fmt, statix, and deadnix formatters
  - Add global exclusions for .git, *.lock, and result directories
  - Verify `nix fmt` and `nix flake check` commands work correctly
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 2. Refactor overlay to use modern final/prev convention
  - Update overlays/default.nix to use explicit `final: prev:` syntax
  - Change package definition to use `final.callPackage` instead of `prev.buildNpmPackage`
  - Extract claude-code-acp package definition into a proper function for callPackage
  - Verify package builds successfully with `nix build .#claude-code-acp`
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 3. Implement granular unfree package management
  - Create centralized nixpkgsConfig with allowUnfreePredicate in flake.nix
  - Define explicit whitelist of approved unfree packages with justification comments
  - Apply nixpkgsConfig to all pkgs instantiations in perSystem
  - Remove global `allowUnfree = true` from modules/system.nix
  - Verify system builds with `nix build .#darwinConfigurations.lu-mbp.system`
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 4. Add idempotent Age key permission enforcement
  - Add home.activation.sopsAgeKeyPermissions script to modules/home/sops.nix
  - Implement file existence check for ~/.config/sops/age/keys.txt
  - Add chmod 600 enforcement using `run` command for dry-run compatibility
  - Add informative log messages for both success and missing key scenarios
  - Use lib.hm.dag.entryAfter to ensure correct activation ordering
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 5. Refactor dock configuration to use declarative references
  - Remove imperative `let` block from modules/darwin/dock.nix
  - Replace calculated primaryUser and userHome with direct config references
  - Update persistent-others paths to use `config.users.users.${config.system.primaryUser}.home`
  - Verify dock configuration still works after darwin-rebuild switch
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 6. Implement dual-world font management
  - Update modules/home/fonts.nix to install fonts via home.packages
  - Add Nerd Fonts (JetBrainsMono, FiraCode, Hack) with override
  - Add system fonts (inter, source-sans-pro, source-serif-pro)
  - Enable fonts.fontconfig.enable for Unix/CLI application support
  - Add documentation comments explaining Cocoa vs fontconfig architecture
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 7. Configure automated storage management
  - Add nix.gc configuration to modules/system.nix with automatic = true
  - Set garbage collection schedule to weekly (Sunday 2 AM)
  - Configure 30-day retention with --delete-older-than option
  - Enable nix.settings.auto-optimise-store for incremental optimization
  - Add documentation comments explaining rationale for incremental vs periodic optimization
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 8. Add Home Manager file collision handling
  - Add home-manager.backupFileExtension = "backup" to darwin configuration
  - Locate the home-manager configuration block in flake/darwin.nix
  - Add configuration option alongside useGlobalPkgs and useUserPackages
  - Add documentation comment explaining collision handling behavior
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 9. Configure binary cache with Cachix
  - Update determinate-nix.customSettings in modules/system.nix
  - Add lu-nix-config.cachix.org to trusted-substituters list
  - Use lib.concatStringsSep for clean multi-line cache configuration
  - Add placeholder comment for Cachix public key (to be added after cache creation)
  - Add documentation comments with setup instructions for creating and using the cache
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 10. Organize flake-parts overlay architecture
  - Verify overlays are defined at top level in flake.nix (already correct)
  - Verify overlays are applied in perSystem block (already correct)
  - Ensure separation of definition (top-level) from application (perSystem)
  - Add documentation comments explaining flake-parts overlay pattern
  - Verify compatibility with existing flake-parts.lib.mkFlake structure
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [-] 11. Run comprehensive validation and formatting
  - Execute `nix fmt` to format all Nix files in the repository
  - Review and fix any statix linting warnings
  - Review and address any deadnix unused code warnings
  - Run `nix flake check` to verify all checks pass
  - Commit formatted and validated code
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [ ] 12. Perform full system integration test
  - Build complete system with `nix build .#darwinConfigurations.lu-mbp.system`
  - Execute `sudo darwin-rebuild switch --flake .#lu-mbp`
  - Verify Age key permissions are 0600 after activation
  - Verify fonts appear in both GUI applications and terminal
  - Test rollback capability with `darwin-rebuild switch --rollback`
  - Verify all existing functionality still works as expected
  - _Requirements: All requirements (integration test)_
