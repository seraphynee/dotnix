{ __findFile, ... }:
{
  den.aspects.desktop._.qs.provides = {
    dms = {
      includes = [ <desktop/qs> ];

      nixos = {
        programs.dms-shell.enable = true;
      };
    };
  };
}
