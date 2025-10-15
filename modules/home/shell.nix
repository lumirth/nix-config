{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Fish shell configuration
  programs.fish = {
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
    shellInit = ''
      # Set editor for Nix compatibility
      set -gx EDITOR zed

      # Initialize zoxide if available
      if command -q zoxide
        zoxide init fish | source
      end

      # iTerm2 shell integration
      test -e ~/.iterm2_shell_integration.fish && source ~/.iterm2_shell_integration.fish

      # Disable fish greeting - we'll use a custom one
      set fish_greeting

      # Tide prompt configuration (Lean style and custom options)
      set -U tide_style Lean
      set -U tide_prompt_colors '16 colors'
      set -U tide_show_time '12-hour format'
      set -U tide_lean_prompt_height 'Two lines'
      set -U tide_prompt_connection Dotted
      set -U tide_prompt_spacing Compact
      set -U tide_icons 'Many icons'
      set -U tide_transient Yes
    '';

    # Custom functions
    functions = {
      # Custom fish greeting
      fish_greeting = ''
        if command -q fortune
          fortune -a
        else
          echo "Welcome to fish shell! 🐟"
        end
      '';

      # Disable vi mode prompt
      fish_mode_prompt = ''
        # Disable default vi prompt
      '';
    };

    # Fish plugins
    plugins = [
      {
        name = "tide";
        src = pkgs.fishPlugins.tide.src;
      }
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }
      {
        name = "done";
        src = pkgs.fishPlugins.done.src;
      }
    ];
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
    enableFishIntegration = true;
  };

  # Configure fzf
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
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

  # Fish configuration files
  xdg.configFile = {
    "fish/conf.d/nix.fish".text = ''
      # Ensure Nix packages are in PATH
      if test -d ~/.nix-profile/bin
        set -gx PATH ~/.nix-profile/bin $PATH
      end

      if test -d /etc/profiles/per-user/$USER/bin
        set -gx PATH /etc/profiles/per-user/$USER/bin $PATH
      end
    '';

    "fish/conf.d/fzf.fish".text = ''
      # Enhanced FZF configuration
      if command -q fzf
        set -gx FZF_DEFAULT_OPTS "--ansi"

        # Use fd if available
        if command -q fd
          set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --follow --exclude .git"
          set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
        end

        # Enhanced preview options
        set -gx FZF_ALT_C_OPTS "--preview 'tree -C {} | head -200'"
        set -gx FZF_CTRL_R_OPTS "--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"
      end
    '';
  };

  # iTerm2 shell integration
  home.file.".iterm2_shell_integration.fish" = {
    source = pkgs.fetchurl {
      url = "https://iterm2.com/shell_integration/fish";
      sha256 = "sha256-aKTt7HRMlB7htADkeMavWuPJOQq1EHf27dEIjKgQgo0=";
    };
  };

  # Home Manager manages Tide config directly
  xdg.configFile."fish/conf.d/tide.fish".text = '''';

}
