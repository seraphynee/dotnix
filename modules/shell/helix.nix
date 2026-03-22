{
  den.aspects.shell._.helix = {
    homeManager = {
      xdg.configFile."helix" = {
        source = ../../dots/config/helix;
        recursive = true;
      };
    };

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ helix ];
      };
    darwin =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ helix ];
      };
  };
}
