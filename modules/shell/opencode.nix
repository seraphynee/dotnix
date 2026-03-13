{
  __findFile,
  lib,
  ...
}:
{
  den.aspects.shell._.opencode = _: {
    homeManager =
      { config, ... }:
      {
        programs.opencode = {
          enable = true;
        };
      };
  };
}
