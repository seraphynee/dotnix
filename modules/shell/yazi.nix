{
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
          source = ../../dots/config/yazi;
          recursive = true;
        };
      };
  };
}
