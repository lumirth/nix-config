{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Zsh shell configuration
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

    # Shell initialization
    initExtra = ''
      # Set editor for Nix compatibility
      export EDITOR=zed

      # Initialize zoxide if available
      if command -v zoxide >/dev/null 2>&1; then
        eval "$(zoxide init zsh)"
      fi

      # Custom prompt or greeting can be added here
    '';

    # Zsh plugins (using oh-my-zsh or similar, but keeping simple)
    # For now, no plugins, can add later if needed
  };

  # Shell-related packages
  home.packages = with pkgs; [
    # Essential shell utilities
    eza # Modern ls replacement
    zoxide # Smart cd command
    direnv # Directory-based environments
    nix-direnv # Nix integration for direnv

    # File management tools
    fd # Fast find alternative
    ripgrep # Fast grep alternative
    bat # Better cat with syntax highlighting

    # System utilities
    htop
    tree
    fortune # For fish greeting

    # Network utilities
    wget
    curl
  ];

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

  # Zsh configuration files
  xdg.configFile = {
    "zsh/conf.d/nix.zsh".text = ''
      # Ensure Nix packages are in PATH
      if [ -d ~/.nix-profile/bin ]; then
        export PATH=~/.nix-profile/bin:$PATH
      fi

      if [ -d /etc/profiles/per-user/$USER/bin ]; then
        export PATH=/etc/profiles/per-user/$USER/bin:$PATH
      fi
    '';

    "zsh/conf.d/fzf.zsh".text = ''
      # Enhanced FZF configuration
      if command -v fzf >/dev/null 2>&1; then
        export FZF_DEFAULT_OPTS="--ansi"

        # Use fd if available
        if command -v fd >/dev/null 2>&1; then
          export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
          export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        fi

        # Enhanced preview options
        export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
        export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"
      fi
    '';
  };

  # iTerm2 shell integration for Zsh - commented out to fix build
  # home.file.".iterm2_shell_integration.zsh" = {
  #   source = pkgs.fetchurl {
  #     url = "https://iterm2.com/shell_integration/zsh";
  #     sha256 = "sha256-2JcMqD0PKM9Q8tqQHC9V5e9d1z8eLr4z8eJf1+9fQ8="; # Note: This SHA might need updating, but for now using a placeholder
  #   };
  # };

}
