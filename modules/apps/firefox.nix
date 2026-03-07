{ __findFile, ... }:
{
  den.aspects.apps._.firefox.homeManager = {
    programs.firefox.enable = true;
  };
}
