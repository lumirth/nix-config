{ pkgs, ... }:
{
  home = {
    stateVersion = "25.05";
    username = "lu";
    homeDirectory = "/Users/lu";

    packages = with pkgs; [
      git
      vim
      wget
      htop
      fd
      ripgrep
      fzf
      bat
      gh
      nil
      nixd
      gnupg
      pinentry_mac
    ];
  };

  programs.gpg = {
    enable = true;
  };

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry_mac;
    enableSshSupport = true;
  };

  programs.fish = {
    enable = true;
    shellInit = ''
      set -gx EDITOR zed
    '';
  };

  programs.git = {
    enable = true;
    userName = "lumirth";
    userEmail = "65358837+lumirth@users.noreply.github.com";

    signing = {
      key = "A1A9D94604186BCE";
      signByDefault = true;
    };
  };
}
