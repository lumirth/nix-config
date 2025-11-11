{ pkgs, ... }:
{
  imports = [
    ./darwin/system-settings.nix
    ./darwin/app-preferences.nix
    ./darwin/dock.nix
    ./darwin/touchid-sudo.nix
  ];

  # Determinate Nix manages the Nix daemon configuration
  nix.enable = false;

  determinate-nix.customSettings =
    let
      inherit (pkgs) lib;
    in
    {
      "experimental-features" = "nix-command flakes";
      "trusted-users" = "root lu";

      # Binary caches: NixOS official + nix-community + personal cache
      # Personal cache (lu-nix-config.cachix.org) speeds up builds by providing
      # pre-built custom packages (overlays) and reduces bootstrap time on new machines.
      "trusted-substituters" = lib.concatStringsSep " " [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://lu-nix-config.cachix.org"
      ];

      "trusted-public-keys" = lib.concatStringsSep " " [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        # TODO: Add Cachix public key after cache creation
        # To create and configure the cache:
        # 1. Create a free cache at https://app.cachix.org (name: lu-nix-config)
        # 2. Install cachix CLI (already in modules/home/packages.nix)
        # 3. Authenticate: cachix authtoken <YOUR_TOKEN>
        # 4. Push custom packages: cachix push lu-nix-config $(nix build .#claude-code-acp --print-out-paths)
        # 5. Add the public key here: "lu-nix-config.cachix.org-1:<PUBLIC_KEY>"
        # 6. Rebuild: sudo darwin-rebuild switch --flake .#lu-mbp
      ];

      "max-jobs" = "auto";
      "cores" = "0";

      # Incremental store optimization
      # Deduplicates files in /nix/store as they're added, spreading I/O cost
      # across builds instead of doing a massive periodic scan that locks the system.
      # This adds ~1-2% overhead per build but eliminates multi-hour blocking scans.
      "auto-optimise-store" = "true";
    };

  # Automatic garbage collection
  # Removes old generations and unreferenced store paths to manage disk space
  # Runs weekly on Sunday at 2 AM (low-usage time)
  # Keeps recent builds for rollback capability while cleaning old ones (30-day retention)
  launchd.daemons.nix-gc = {
    script = ''
      ${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 30d
    '';
    serviceConfig = {
      StartCalendarInterval = [
        {
          Weekday = 0; # Sunday
          Hour = 2;
          Minute = 0;
        }
      ];
      StandardOutPath = "/var/log/nix-gc.log";
      StandardErrorPath = "/var/log/nix-gc.log";
    };
  };

  system.stateVersion = 6;
  system.primaryUser = "lu";

  nixpkgs.hostPlatform = "aarch64-darwin";

  # Ensure preferred shell is installed system-wide
  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];

  users.users.lu = {
    name = "lu";
    home = "/Users/lu";
    shell = pkgs.zsh;
  };

  system.activationScripts.validateDeterminateNix = ''
    if ! command -v nix >/dev/null 2>&1; then
      echo "ERROR: Determinate Nix is not installed (nix not found)" >&2
      exit 1
    fi

    if [ ! -r /etc/nix/nix.custom.conf ]; then
      echo "WARNING: /etc/nix/nix.custom.conf missing or unreadable" >&2
    fi

    if command -v determinate-nixd >/dev/null 2>&1; then
      determinate-nixd --version
    else
      echo "WARNING: determinate-nixd daemon not found" >&2
    fi
  '';
}
