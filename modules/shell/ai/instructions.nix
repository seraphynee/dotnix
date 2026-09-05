{ paths, ... }:
{
  den.aspects.shell._.ai = {
    homeManager = {
      home.file.".agents" = {
        source = paths.dots + "/agents";
      };
    };
  };
}
