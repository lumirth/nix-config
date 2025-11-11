{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  # SSH configuration
  sshDir = "${config.home.homeDirectory}/.ssh";
  secretsDir = ./secrets/ssh;
  secretsYamlFile = "${secretsDir}/secrets.yaml";

  # Git configuration
  sshPubSecretName = "ssh_public_key";
  hasManagedSshKey = config.sops.secrets ? sshPubSecretName;
  allowedSigners = "${config.xdg.configHome}/git/allowed_signers";

  # Rectangle Pro configuration
  rectangleDir = "${config.home.homeDirectory}/Library/Application Support/Rectangle Pro";
  rectangleSecretsDir = ./secrets/rectangle-pro;

  # Age key configuration
  ageKeyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  # SSH bootstrap script
  bootstrapScript = ''
    #!/usr/bin/env bash
    set -euo pipefail

    SSH_DIR="${sshDir}"
    SSH_KEY="$SSH_DIR/id_ed25519"
    SSH_PUB_KEY="$SSH_DIR/id_ed25519.pub"

    if [ ! -f "$SSH_KEY" ] || [ ! -f "$SSH_PUB_KEY" ]; then
      echo "SSH keypair not found at $SSH_DIR. Run 'sudo darwin-rebuild switch --flake .#lu-mbp' after adding the encrypted secret." >&2
      exit 1
    fi

    if ! ${pkgs.gh}/bin/gh auth status >/dev/null 2>&1; then
      echo "Authenticating GitHub CLI (browser will open)..."
      PATH="/usr/bin:/bin:$PATH" \
        GIT_EXEC_PATH="${pkgs.git}/libexec/git-core" \
        ${pkgs.gh}/bin/gh auth login -p https -h github.com -w -s admin:public_key,admin:ssh_signing_key
    fi

    KEY_TITLE="$(/usr/sbin/scutil --get ComputerName)-$(date +%Y%m%d-%H%M%S)"
    SSH_KEY_CONTENT="$(awk '{print $1" "$2}' "$SSH_PUB_KEY")"

    if ! ${pkgs.gh}/bin/gh api /user/keys 2>/dev/null | grep -q "$SSH_KEY_CONTENT"; then
      PATH="/usr/bin:/bin:$PATH" \
        GIT_EXEC_PATH="${pkgs.git}/libexec/git-core" \
        ${pkgs.gh}/bin/gh ssh-key add "$SSH_PUB_KEY" --title "$KEY_TITLE"
    else
      echo "✓ SSH authentication key already present on GitHub"
    fi

    if ! ${pkgs.gh}/bin/gh api /user/ssh_signing_keys 2>/dev/null | grep -q "$SSH_KEY_CONTENT"; then
      PATH="/usr/bin:/bin:$PATH" \
        GIT_EXEC_PATH="${pkgs.git}/libexec/git-core" \
        ${pkgs.gh}/bin/gh ssh-key add "$SSH_PUB_KEY" --title "$KEY_TITLE" --type signing
    else
      echo "✓ SSH signing key already present on GitHub"
    fi

    echo "SSH bootstrap complete. Test with: ssh -T git@github.com"
  '';
in
{
  # ============================================================================
  # Home Manager Configuration
  # ============================================================================

  home = {
    stateVersion = "25.05";
    username = "lu";
    homeDirectory = "/Users/lu";
  };

  # ============================================================================
  # Imports
  # ============================================================================

  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  # ============================================================================
  # Assertions
  # ============================================================================

  # Note: Age key assertion removed because builtins.pathExists fails in pure evaluation
  # (nix flake check, CI/CD). The sops-nix module will fail at activation time if the key
  # is missing, which is sufficient. See docs/BOOTSTRAP.md for setup instructions.
  assertions = [ ];

  # ============================================================================
  # Packages
  # ============================================================================

  home.packages = with pkgs; [
    # Version control
    git
    gh

    # Development tools
    python3
    pipx
    vim
    devenv
    cachix
    nodejs_22

    # Nix language servers
    nil
    nixd

    # Utilities
    unar # Archive extraction
    jq # JSON processor
    yq # YAML processor
    eza
    zoxide
    direnv
    nix-direnv
    fd
    ripgrep
    bat
    htop
    tree
    fortune
    wget
    curl

    # Additional packages
    bitwarden-cli
    infisical
    cursor-cli
    ghost-cli
    claude-code

    # Fonts
    # Nerd Fonts for terminal and coding
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack

    # System fonts for general use
    inter # Modern sans-serif, excellent for UI
    source-sans-pro # Adobe's open-source sans-serif
    source-serif-pro # Adobe's open-source serif
  ];

  # ============================================================================
  # Fonts
  # ============================================================================

  # Dual-World Font Management for macOS
  #
  # macOS has two separate font systems that need to be configured:
  #
  # 1. Cocoa (Native macOS Framework):
  #    - Used by native macOS applications (Safari, Finder, VSCode, etc.)
  #    - Reads fonts from ~/Library/Fonts/ and system font directories
  #    - Home Manager on nix-darwin automatically symlinks fonts to:
  #      ~/Library/Fonts/HomeManager/
  #
  # 2. fontconfig (Unix/Linux Standard):
  #    - Used by Unix/CLI applications (Terminal, Emacs, CLI tools, etc.)
  #    - Reads configuration from ~/.config/fontconfig/fonts.conf
  #    - Requires explicit enablement via fonts.fontconfig.enable
  #
  # By installing fonts via home.packages and enabling fontconfig,
  # we ensure fonts work in BOTH native macOS apps and Unix applications.

  fonts.fontconfig.enable = true;

  # ============================================================================
  # Shell Configuration
  # ============================================================================

  programs.zsh = {
    enable = true;

    # Shell aliases
    shellAliases = {
      clip = "pbcopy";
      ls = "eza --group-directories-first";
      la = "ls -a";
      ll = "ls --git -l";
      lt = "ls --tree -D -L 2 -I \"cache|log|logs|node_modules|vendor\"";
      ltt = "ls --tree -D -L 3 -I \"cache|log|logs|node_modules|vendor\"";
      lttt = "ls --tree -D -L 4 -I \"cache|log|logs|node_modules|vendor\"";
      py = "python";
    };
  };

  # Configure direnv for Nix integration
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Configure zoxide
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Configure fzf
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [
      "--ansi"
      "--height 40%"
      "--layout=reverse"
      "--border"
    ];
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
  };

  # Environment variables
  home.sessionVariables = {
    EDITOR = "zed";
    PAGER = "less";
    LESS = "-R";
  };

  # ============================================================================
  # Git Configuration
  # ============================================================================

  programs.git = {
    enable = true;
    userName = "lumirth";
    userEmail = "65358837+lumirth@users.noreply.github.com";

    signing = lib.mkIf hasManagedSshKey {
      key = config.sops.secrets."${sshPubSecretName}".path;
      signByDefault = true;
    };

    extraConfig = {
      # Use SSH for commit signing
      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = allowedSigners;

      # Additional Git settings
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };

    # Git aliases for common operations
    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      visual = "!gitk";
    };
  };

  home.activation.setupAllowedSigners = lib.mkIf hasManagedSshKey (
    lib.hm.dag.entryAfter [ "sops-install-secrets" ] ''
      ALLOWED_SIGNERS='${allowedSigners}'
      SSH_PUB_FILE='${config.sops.secrets."${sshPubSecretName}".path}'

      if [ ! -f "$SSH_PUB_FILE" ]; then
        warnEcho "sops-nix key $SSH_PUB_FILE not found; skipping allowed_signers update"
        exit 0
      fi

      run mkdir -p "$(dirname "$ALLOWED_SIGNERS")"
      noteEcho "Updating git allowed_signers at $ALLOWED_SIGNERS"
      ${pkgs.coreutils}/bin/printf "%s %s\n" "${config.programs.git.userEmail}" "$(${pkgs.coreutils}/bin/cat "$SSH_PUB_FILE")" > "$ALLOWED_SIGNERS"
      run chmod 644 "$ALLOWED_SIGNERS"
    ''
  );

  # ============================================================================
  # SSH Configuration
  # ============================================================================

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      extraOptions = {
        AddKeysToAgent = "yes";
        UseKeychain = "yes";
      };
    };
  };

  home.activation.ensureSshDir = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    run mkdir -p '${sshDir}'
    run chmod 700 '${sshDir}'
  '';

  sops.secrets."ssh_private_key" = {
    sopsFile = secretsYamlFile;
    path = "${sshDir}/id_ed25519";
    mode = "0600";
  };

  sops.secrets."ssh_public_key" = {
    sopsFile = secretsYamlFile;
    path = "${sshDir}/id_ed25519.pub";
    mode = "0644";
  };

  home.file."bin/bootstrap-ssh.sh" = {
    text = bootstrapScript;
    executable = true;
  };

  # ============================================================================
  # Secrets Management (sops-nix)
  # ============================================================================

  sops.age.keyFile = ageKeyFile;
  # Age key hydration must happen manually (see devshell hook).

  # Idempotent permission enforcement for Age key
  # Ensures the sops-nix Age key has correct permissions (0600) on every activation
  home.activation.sopsAgeKeyPermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -f "${ageKeyFile}" ]; then
      run chmod 600 "${ageKeyFile}"
      $DRY_RUN_CMD echo "✓ Enforced 0600 permissions on Age key: ${ageKeyFile}"
    else
      $DRY_RUN_CMD echo "⚠ Age key not found (run bin/infisical-bootstrap-sops first): ${ageKeyFile}"
    fi
  '';

  # ============================================================================
  # Application Configuration - Rectangle Pro
  # ============================================================================

  # Ensure the Rectangle Pro support directory exists before secrets are written
  home.activation.ensureRectangleProDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p '${rectangleDir}'
  '';

  sops.secrets."rectangle-pro-padl" = {
    format = "binary";
    sopsFile = "${rectangleSecretsDir}/580977.padl";
    path = "${rectangleDir}/580977.padl";
    mode = "0600";
  };

  sops.secrets."rectangle-pro-spadl" = {
    format = "binary";
    sopsFile = "${rectangleSecretsDir}/580977.spadl";
    path = "${rectangleDir}/580977.spadl";
    mode = "0600";
  };
}
