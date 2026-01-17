{
  config,
  pkgs,
  inputs,
  ...
}:
let
  inherit (pkgs) lib;
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
    # ==========================================================================
    # Project Environment Management
    # ==========================================================================
    mise # Primary tool for project environments (new projects use mise)

    # Legacy: kept for backward compatibility with existing projects using devenv.nix
    devenv

    # ==========================================================================
    # Language Runtimes & Tooling
    # ==========================================================================
    python3
    pipx
    uv # Modern Python package manager (10-100x faster than pip)
    nodejs_22
    nodePackages.pnpm # Faster npm alternative, disk-efficient
    ruby_3_3 # Current Ruby (replaces ancient system 2.6)
    go # Go toolchain
    rustup # Rust toolchain manager

    # ==========================================================================
    # Build Tools
    # ==========================================================================
    cmake # Required for native extensions (Python C-extensions, Node gyp)
    cachix

    # ==========================================================================
    # Language Servers (for IDE support)
    # ==========================================================================
    nil # Nix LSP
    nixd # Alternative Nix LSP
    nodePackages.typescript-language-server # JS/TS LSP
    pyright # Python LSP

    # ==========================================================================
    # Editors
    # ==========================================================================
    vim
    micro

    # ==========================================================================
    # Shell & Terminal
    # ==========================================================================
    zsh-defer
    zsh-autosuggestions
    zsh-history-substring-search
    zsh-syntax-highlighting
    starship

    # ==========================================================================
    # CLI Utilities
    # ==========================================================================
    comma # Run any nixpkgs package with ", foo" (e.g., , cowsay "hello")
    nix-index # Database for comma - run "nix-index" once to build, then ", foo" works
    unar # Archive extraction
    jq # JSON processor
    yq # YAML processor
    eza # Modern ls
    fd # Modern find
    ripgrep # Modern grep
    bat # Modern cat
    htop
    tree
    fortune
    wget
    curl

    # ==========================================================================
    # Cloud & DevOps
    # ==========================================================================
    bitwarden-cli
    infisical
    cursor-cli
    ghost-cli
    colima
    docker

    # ==========================================================================
    # Coding Tools
    # ==========================================================================
    claude-code
    claude-code-acp
    sshpass
    sshfs

    # ==========================================================================
    # Fonts
    # ==========================================================================
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

  programs.zsh = lib.mkMerge [
    {
      enable = true;
      enableCompletion = true;
      completionInit = ''
        autoload -Uz compinit
        # Rebuild completion dump at most once per 24h
        if [[ -n ${"ZDOTDIR:-$HOME"}/.zcompdump(#qN.mh+24) ]]; then
          compinit
        else
          compinit -C
        fi
      '';
      setOptions = [
        "NO_INTERACTIVE_COMMENTS"
        "NO_NOMATCH"
      ];

      history = {
        size = 10000;
        save = 10000;
        path = "${config.home.homeDirectory}/.zsh_history";
        share = true;
        extended = true;
        ignoreSpace = true;
        ignoreDups = true;
        expireDuplicatesFirst = true;
      };

      # Plugin integrations handled manually with zsh-defer
      autosuggestion.enable = false;
      syntaxHighlighting.enable = false;

      shellAliases = {
        z = "zoxide query";
        clip = "pbcopy";
        paste = "pbpaste";
        ls = "eza --group-directories-first --icons";
        la = "ls -a";
        ll = "ls --git -lh";
        tree = "eza --tree --icons";
        lt = "tree -L 2 -I 'cache|log|logs|node_modules|vendor'";
        py = "python3";
        pip = "python3 -m pip";
        cat = "bat --style=plain --paging=never";
        nano = "micro";
        grep = "rg --hidden --smart-case";
        find = "fd --hidden";
        g = "git";
        gst = "git status";
        gco = "git checkout";
        gcm = "git commit -m";
        gp = "git push";
        gl = "git pull";
        ncg = "nix-collect-garbage -d";
        nfu = "nix flake update";
        d = "docker";
        dc = "docker-compose";

        # Quick nix package runners (alternative to comma)
        nr = "nix run nixpkgs#";
        ns = "nix shell nixpkgs#";
        nsr = "nix search nixpkgs";

        # Darwin rebuild aliases
        ds = "sudo darwin-rebuild switch --flake ~/.config/nix#lu-mbp";
        dbuild = "darwin-rebuild build --flake ~/.config/nix#lu-mbp";
        dcheck = "nix flake check ~/.config/nix";
        drollback = "darwin-rebuild rollback";
        dgens = "darwin-rebuild --list-generations";
        dsu = "(cd ~/.config/nix && nix flake update && sudo darwin-rebuild switch --flake .#lu-mbp)";

        # Config editing and navigation
        nconfig = "$EDITOR ~/.config/nix";
        cnix = "cd ~/.config/nix";
      };
    }
    {
      initContent = ''
        # Enable for startup profiling: uncomment the next line, open a login shell, then run `zprof`
        # zmodload zsh/zprof

        # zsh-defer speeds up startup by loading non-critical pieces after first prompt
        if [[ -f ${pkgs.zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh ]]; then
          source ${pkgs.zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh
        fi

        bindkey '^[[1;5C' forward-word
        bindkey '^[[1;5D' backward-word

        setopt AUTO_PUSHD
        setopt PUSHD_IGNORE_DUPS
        setopt PUSHD_SILENT
        setopt CDABLE_VARS
        setopt EXTENDED_GLOB
        unsetopt INTERACTIVE_COMMENTS

        autoload -Uz select-word-style
        select-word-style bash

        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"

        # Prompt first, then heavier integrations
        eval "$(starship init zsh)"

        # direnv stays synchronous so project envs load immediately
        eval "$(direnv hook zsh)"

        # mise for language version management (synchronous for immediate availability)
        eval "$(mise activate zsh)"

        if typeset -f zsh-defer >/dev/null; then
          zsh-defer eval "$(zoxide init zsh --cmd cd)"
          zsh-defer eval "$(atuin init zsh --disable-up-arrow)"
          zsh-defer eval "$(fzf --zsh)"

          zsh-defer source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
          zsh-defer source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
          zsh-defer eval 'source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh; bindkey "^[[A" history-substring-search-up; bindkey "^[OA" history-substring-search-up; bindkey "^[[B" history-substring-search-down; bindkey "^[OB" history-substring-search-down'
        else
          eval "$(zoxide init zsh --cmd cd)"
          eval "$(atuin init zsh --disable-up-arrow)"
          eval "$(fzf --zsh)"

          source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
          source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
          source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh
          bindkey "^[[A" history-substring-search-up
          bindkey "^[OA" history-substring-search-up
          bindkey "^[[B" history-substring-search-down
          bindkey "^[OB" history-substring-search-down
        fi
      '';
    }
  ];

  # Configure direnv for Nix integration
  programs.direnv = {
    enable = true;
    enableZshIntegration = false;
    nix-direnv.enable = true;
  };

  # Configure zoxide
  programs.zoxide = {
    enable = true;
    enableZshIntegration = false;
    options = [ "--cmd cd" ];
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = false;
    settings = {
      auto_sync = false;
      search_mode = "fuzzy";
      style = "compact";
    };
  };

  # Configure fzf
  programs.fzf = {
    enable = true;
    enableZshIntegration = false;
    defaultOptions = [
      "--ansi"
      "--height 40%"
      "--layout=reverse"
      "--border"
    ];
    defaultCommand = "fd --type f --hidden --exclude .git";
    fileWidgetCommand = "fd --type f --hidden --exclude .git";
    changeDirWidgetCommand = "fd --type d";
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = false;
    package = pkgs.starship;

    settings = {
      scan_timeout = 10;
      command_timeout = 300;
      format = "$directory$git_branch$git_status$nix_shell$character";
      add_newline = true;

      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[✗](bold red)";
        vimcmd_symbol = "[←](bold green)";
      };

      directory = {
        truncation_length = 3;
        truncation_symbol = "…/";
        truncate_to_repo = true;
        style = "bold cyan";
        read_only = " 󰌾";
        home_symbol = "~";
      };

      nix_shell = {
        format = " [$state$name]($style)";
        symbol = "";
        style = "bold blue";
        impure_msg = "!impure ";
        pure_msg = "nix ";
        unknown_msg = "";
      };

      git_branch = {
        symbol = "";
        format = " [$branch]($style)";
        style = "bold purple";
      };

      git_status = {
        format = "[$all_status$ahead_behind]($style)";
        style = "bold red";
        conflicted = "C$count ";
        ahead = "↑$count ";
        behind = "↓$count ";
        diverged = "↕$ahead_count/$behind_count ";
        untracked = "?$count ";
        stashed = "s$count ";
        modified = "~$count ";
        staged = "+$count ";
        renamed = ">$count ";
        deleted = "-$count ";
      };

      package.disabled = true;
      aws.disabled = true;
      gcloud.disabled = true;
    };
  };

  # Environment variables
  home.sessionVariables = {
    EDITOR = "zed";
    VISUAL = "micro";
    PAGER = "less";
    LESS = "-R";
  };

  # ============================================================================
  # Git Configuration
  # ============================================================================

  programs.git = {
    enable = true;

    signing = {
      key = config.sops.secrets."${sshPubSecretName}".path;
      format = "ssh";
      signByDefault = true;
    };

    settings = {
      user = {
        name = "lumirth";
        email = "65358837+lumirth@users.noreply.github.com";
      };

      # Use SSH for commit signing
      gpg = {
        format = "ssh";
        ssh.allowedSignersFile = allowedSigners;
      };

      # Additional Git settings
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;

      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        visual = "!gitk";
      };
    };
  };

  # Declaratively generate allowed_signers file from sops-managed public key
  # We use sops-nix templates feature to generate the file with the decrypted public key content
  sops.templates."git-allowed-signers" = {
    content = ''
      ${config.programs.git.settings.user.email} ${config.sops.placeholder."${sshPubSecretName}"}
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
