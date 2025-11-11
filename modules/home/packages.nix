{ pkgs, ... }:
{
  home.packages = (
    with pkgs;
    [
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
      claude-code-acp
    ]
  );
}
