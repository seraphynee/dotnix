{
  den.aspects.shell._.zellij = {
    homeManager = {
      xdg.configFile."zellij" = {
        source = ../../dots/config/zellij;
        recursive = true;
      };
    };

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ zellij ];
      };
  };
}
