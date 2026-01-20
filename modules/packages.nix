{ pkgs, ... }:
{
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
    # Note: comma and nix-index are now provided by nix-index-database module
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
    opencode

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
}
