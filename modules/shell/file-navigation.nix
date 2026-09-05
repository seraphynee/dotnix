{ paths, ... }:
{
  # Lla
  den.aspects.shell._.lla.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.lla ];
      xdg.configFile."lla/config.toml".source = paths.dots + "/config/lla/config.toml";
    };
  # Pet
  den.aspects.shell._.pet.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.pet ];
      xdg.configFile."pet" = {
        source = paths.dots + "/config/pet";
        recursive = true;
      };
    };
  # Superfile
  den.aspects.shell._.superfile.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.superfile ];
      xdg.configFile."superfile/config.toml".source = paths.dots + "/config/superfile/config.toml";
    };
  # Television
  den.aspects.shell._.television.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.television ];
      xdg.configFile."television" = {
        source = paths.dots + "/config/television";
        recursive = true;
      };
    };
  # Yazi
  den.aspects.shell._.yazi = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          yazi
        ];
      };

    homeManager =
      { pkgs, ... }:
      {
        xdg.configFile."yazi" = {
          source = paths.dots + "/config/yazi";
          recursive = true;
        };
      };
  };
}
