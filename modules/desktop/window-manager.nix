{ __findFile }:
{
  den.aspects.desktop._.wm._ = {
    niri = {
      includes = [ <desktop/sddm> ];

      nixos =
        { pkgs, ... }:
        {
          environment.systemPackages = with pkgs; [
            fuzzel
            alacritty
          ];

          services.xserver.enable = true;
          services.xserver.xkb.layout = "us";

          programs.niri.enable = true;
          security.polkit.enable = true;
        };

      # homeManager = {
      #   #      xdg.configFile."niri/config.kdl".source = ../../dots/config/niri/config.kdl;
      # };
    };

    mangowc = { };
  };
}
