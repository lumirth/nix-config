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

  # Determinate Nix reads custom settings from /etc/nix/nix.custom.conf.
  # Writing the file explicitly keeps the concerns separated and avoids
  # touching nix-darwin's deprecated nix.* namespace while nix.enable = false.
  environment.etc."nix/nix.custom.conf".text = ''
    experimental-features = nix-command flakes
    trusted-users = root lu
    trusted-substituters = https://cache.nixos.org https://nix-community.cachix.org
    trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
    max-jobs = auto
    cores = 0
  '';

  system.stateVersion = 6;
  system.primaryUser = "lu";

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

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
