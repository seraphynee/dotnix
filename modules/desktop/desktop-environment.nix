{ __findFile, ... }:
{
  den.aspects.desktop._.de._ = {
    gnome = {
      nixos = {
        services = {
          xserver = {
            enable = true;
            xkb.layout = "us";
          };
          displayManager.gdm.enable = true;
          desktopManager.gnome.enable = true;
        };
      };
    };

    kde = {
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
  };
}
