# Shared nixpkgs configuration
# Single source of truth for unfree package allowances
# This prevents configuration drift between flake.nix and flake/darwin.nix
{ lib }:
{
  # Explicit unfree package whitelist for better security and licensing control
  # This replaces the global allowUnfree = true pattern
  allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      # GUI Applications (installed via Homebrew casks, but may have Nix equivalents)
      "vscode" # Code editor - Microsoft proprietary license
      "cursor" # AI-powered code editor - proprietary license
      "obsidian" # Knowledge base - Obsidian EULA
      "slack" # Team communication - proprietary license

      # CLI Tools with unfree licenses
      "cursor-cli" # Cursor CLI tool - proprietary license
      "claude-code" # Anthropic's agentic coding tool - proprietary license

      # Add additional unfree packages here as needed with justification comments
    ];
}
