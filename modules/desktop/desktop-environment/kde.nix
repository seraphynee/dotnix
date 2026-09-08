{ __findFile, ... }:
{
  den.aspects.desktop._.de._.kde = {
    includes = [ <desktop/noctalia-greeter> ];

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
