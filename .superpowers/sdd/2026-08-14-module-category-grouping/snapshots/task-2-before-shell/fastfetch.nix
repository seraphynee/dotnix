{
  den.aspects.shell._.fastfetch = {
    homeManager = {
      xdg.configFile."fastfetch/config.jsonc".source = ../../dots/config/fastfetch/config.jsonc;
    };
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ fastfetch ];
      };
    darwin =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ fastfetch ];
      };
  };
}
