{
  __findFile,
  constants,
  ...
}:
{
  den.aspects.system._.locale = {
    nixos = {
      i18n.defaultLocale = "en_US.UTF-8";
      time.timeZone = "Asia/Jakarta";
      # services.timesyncd.enable = true;
    };
  };

  den.aspects.system._.settings = {
    nixos = {
      services = {
        power-profiles-daemon.enable = true; # alternatively, use tuned.enable = true
        upower.enable = true;
      };
      security.pam.services.login.enableGnomeKeyring = true;
    };
    darwin = {
      system.defaults = {
        spaces.spans-displays = false;
        menuExtraClock = {
          Show24Hour = true;
          IsAnalog = false;
        };
        finder = {
          ShowPathbar = true;
        };
        dock = {
          mru-spaces = false; # Whether to automatically rearrange spaces based on most recent use
          tilesize = 36;
          autohide = true;
          orientation = "bottom";
          show-recents = false;
          autohide-time-modifier = 0.5;
          autohide-delay = 0.1;
        };

        NSGlobalDomain._HIHideMenuBar = false;
      };
    };
  };

  den.aspects.system._.wsl =
    { inputs, ... }:
    {
      nixos = {
        imports = with inputs; [ inputs.nixos-wsl.nixosModules.wsl ];

        wsl = {
          enable = true;
          defaultUser = "${constants.user_one}";
          docker-desktop.enable = true;
        };
      };
    };
}
