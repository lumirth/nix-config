{ pkgs, ... }:
{
  environment.etc."pam.d/sudo_local".text = ''
    # sudo_local survives system updates; include pam_tid for Touch ID auth
    auth       sufficient     pam_tid.so
  '';
}
