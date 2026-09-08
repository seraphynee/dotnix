{
  __findFile,
  inputs,
  ...
}:
{
  den.aspects.desktop._.qs.provides.dms = {
    includes = [ <desktop/qs> ];

    nixos =
      { pkgs, ... }:
      let
        dmsPackages = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system};
      in
      {
        programs.dms-shell = {
          enable = true;
          package = dmsPackages.dms-shell;
          quickshell.package = dmsPackages.quickshell;
        };
      };
  };
}
