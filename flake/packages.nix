{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ inputs.self.overlays.default ];
        config.allowUnfree = true;
      };
    in
    {
      _module.args.pkgs = pkgs;
      formatter = pkgs.nixpkgs-fmt;
    };
}
