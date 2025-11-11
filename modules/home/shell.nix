{ config
, lib
, pkgs
, ...
}:
{
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

    # Zsh plugins (using oh-my-zsh or similar, but keeping simple)
    # For now, no plugins, can add later if needed
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

}
