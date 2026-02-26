{ __findFile, ... }:
{
  den.aspects.desktop._.gnome = {
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
}
