{
  den.aspects.shell._.aerospace = {
    homeManager = {
      xdg.configFile."aerospace" = {
        source = ../../dots/config/aerospace;
        recursive = true;
      };
    };

    darwin =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ aerospace ];
      };
  };
}
