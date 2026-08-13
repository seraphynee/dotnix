{ inputs, ... }:
{
  den.aspects.shell._.msnap = {
    nixos =
      { pkgs, ... }:
      {
        nixpkgs.overlays = [ inputs.msnap.overlays.default ];
        environment.systemPackages = [ pkgs.msnap ];
      };
  };
}
