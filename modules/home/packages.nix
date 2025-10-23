{ pkgs, ... }:
{
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

    # Nix language servers
    nil
    nixd

    # Utilities
    unar # Archive extraction
    jq # JSON processor
    yq # YAML processor

    # Additional packages
    bitwarden-cli
  ];
}
