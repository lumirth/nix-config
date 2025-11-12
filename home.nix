{
  config,
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
  allowedSigners = "${config.xdg.configHome}/git/allowed_signers";

  # Rectangle Pro configuration
  rectangleDir = "${config.home.homeDirectory}/Library/Application Support/Rectangle Pro";
  rectangleSecretsDir = ./secrets/rectangle-pro;

  # Age key configuration
  ageKeyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

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
    claude-code-acp

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

    signing = {
      key = config.sops.secrets."${sshPubSecretName}".path;
      format = "ssh";
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

  # Declaratively generate allowed_signers file from sops-managed public key
  # We use sops-nix templates feature to generate the file with the decrypted public key content
  sops.templates."git-allowed-signers" = {
    content = ''
      ${config.programs.git.userEmail} ${config.sops.placeholder."${sshPubSecretName}"}
    '';
    path = allowedSigners;
    mode = "0644";
  };

  # ============================================================================
  # GitHub CLI Configuration
  # ============================================================================

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
    };
  };

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

  # ============================================================================
  # Secrets Management (sops-nix)
  # ============================================================================

  sops.age.keyFile = ageKeyFile;
  # Age key hydration must happen manually (see devshell hook).

  # ============================================================================
  # Application Configuration - Rectangle Pro
  # ============================================================================

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
