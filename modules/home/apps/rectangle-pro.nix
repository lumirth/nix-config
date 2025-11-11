{ config, lib, ... }:
let
  rectangleDir = "${config.home.homeDirectory}/Library/Application Support/Rectangle Pro";
  secretsDir = ../../../secrets/rectangle-pro;
in
{
  # Ensure the Rectangle Pro support directory exists before secrets are written
  home.activation.ensureRectangleProDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p '${rectangleDir}'
  '';

  sops.secrets."rectangle-pro-padl" = {
    format = "binary";
    sopsFile = "${secretsDir}/580977.padl";
    path = "${rectangleDir}/580977.padl";
    mode = "0600";
  };

  sops.secrets."rectangle-pro-spadl" = {
    format = "binary";
    sopsFile = "${secretsDir}/580977.spadl";
    path = "${rectangleDir}/580977.spadl";
    mode = "0600";
  };
}
