_: {
  den.aspects.desktop._.de._.gnome = {
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
