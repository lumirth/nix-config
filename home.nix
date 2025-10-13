{
  config,
  lib,
  pkgs,
  ...
}:
{
  home = {
    stateVersion = "25.05";
    username = "lu";
    homeDirectory = "/Users/lu";

    packages = with pkgs; [
      git
      vim
      wget
      htop
      fd
      ripgrep
      fzf
      bat
      gh
      nil
      nixd
      gnupg
      pinentry_mac
    ];
  };

  programs.gpg = {
    enable = true;
    homedir = "${config.home.homeDirectory}/.gnupg";
  };

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry_mac;
    enableSshSupport = true;
  };

  # Symlink .gnupg to iCloud Drive for syncing across devices
  # Also fix permissions since iCloud doesn't preserve them reliably
  home.activation.symlinkGnupg = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ICLOUD_GNUPG="$HOME/Library/Mobile Documents/com~apple~CloudDocs/.gnupg"
    GNUPG_HOME="$HOME/.gnupg"

    # Only create symlink if iCloud directory exists and local isn't already a symlink to it
    if [ -d "$ICLOUD_GNUPG" ] && [ ! -L "$GNUPG_HOME" ]; then
      echo "Setting up .gnupg symlink to iCloud..."
      if [ -e "$GNUPG_HOME" ]; then
        echo "Warning: $GNUPG_HOME already exists but is not a symlink to iCloud"
      else
        ln -sf "$ICLOUD_GNUPG" "$GNUPG_HOME"
      fi
    fi

    # Fix permissions - GPG requires strict permissions and iCloud doesn't preserve them
    if [ -d "$ICLOUD_GNUPG" ]; then
      echo "Fixing .gnupg permissions..."

      # Main directory must be 700
      chmod 700 "$ICLOUD_GNUPG" 2>/dev/null || true

      # Private keys directory and contents must be restrictive
      if [ -d "$ICLOUD_GNUPG/private-keys-v1.d" ]; then
        chmod 700 "$ICLOUD_GNUPG/private-keys-v1.d"
        find "$ICLOUD_GNUPG/private-keys-v1.d" -type f -exec chmod 600 {} \; 2>/dev/null || true
      fi

      # Revocation certificates directory and contents
      if [ -d "$ICLOUD_GNUPG/openpgp-revocs.d" ]; then
        chmod 700 "$ICLOUD_GNUPG/openpgp-revocs.d"
        find "$ICLOUD_GNUPG/openpgp-revocs.d" -type f -exec chmod 600 {} \; 2>/dev/null || true
      fi

      # Key files should be 600
      for file in pubring.kbx pubring.kbx~ trustdb.gpg tofu.db sshcontrol pubring.gpg secring.gpg; do
        if [ -f "$ICLOUD_GNUPG/$file" ]; then
          chmod 600 "$ICLOUD_GNUPG/$file" 2>/dev/null || true
        fi
      done

      echo "Permissions fixed for .gnupg"
    fi
  '';

  programs.fish = {
    enable = true;
    shellInit = ''
      set -gx EDITOR zed
    '';
  };

  programs.git = {
    enable = true;
    userName = "lumirth";
    userEmail = "65358837+lumirth@users.noreply.github.com";

    signing = {
      key = "A1A9D94604186BCE";
      signByDefault = true;
    };
  };
}
