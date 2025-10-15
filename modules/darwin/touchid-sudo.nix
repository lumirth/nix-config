{ pkgs, ... }:

{
  # Enable TouchID for sudo by managing the sudo_local file through Nix
  # This uses the modern macOS approach that persists through system updates
  environment.etc."pam.d/sudo_local".text = ''
    # sudo_local: local config file which survives system update and is included for sudo
    # Touch ID support enabled via nix-darwin
    auth       sufficient     pam_tid.so
  '';
}
