{ __findFile, ... }:
{
  den.aspects.desktop._.kde = {
    includes = [ <desktop/sddm> ];
    nixos = {
      services = {
        xserver = {
          enable = true;
          xkb.layout = "us";
        };
        desktopManager.plasma6.enable = true;
      };
      programs.kdeconnect.enable = true;
    };
  };
}
