{
  den.aspects.system._.xdg = {
    nixos =
      { pkgs, config, ... }:
      {
        programs.dconf.enable = true;

        xdg.portal = {
          enable = true;
          # Use portal-backed xdg-open only on full desktop environments
          # like GNOME or KDE Plasma.
          xdgOpenUsePortal =
            (config.services.desktopManager.gnome.enable or false)
            || (config.services.desktopManager.plasma6.enable or false);
          extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
          config.common = {
            default = [ "gtk" ];
            "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
          };
        };
      };

    homeManager = _: {
      home.sessionVariables = {
        TERMINAL = "ghostty";
        BROWSER = "zen-beta";
        EDITOR = "nvim";
        PAGER = "less";
        GIT_EDITOR = "nvim";
        GTK_THEME = "Adwaita:dark";
        # AUDIO_PLAYER = "mpv";
        # VIDEO_PLAYER = "mpv";
      };

      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          gtk-theme = "Adwaita-dark";
        };
      };

      xdg =
        let
          browser = [ "zen-beta.desktop" ];
          fileManager = [ "org.gnome.Nautilus.desktop" ];
          editor = [ "code.desktop" ];
          player = [ "mpv.desktop" ];
          viewer = [ "nsxiv.desktop" ];
          reader = [ "org.pwmt.zathura.desktop" ];
          defaults = {
            "application/pdf" = reader;
            "application/epub" = reader;
            "application/epub+zip" = reader;

            "text/html" = browser;
            "text/xml" = browser;
            "text/plain" = editor;
            "text/*" = editor;
            "application/x-wine-extension-ini" = editor;

            "application/json" = browser;
            "application/xml" = browser;
            "application/xhtml+xml" = browser;
            "application/xhtml_xml" = browser;
            "application/rdf+xml" = browser;
            "application/rss+xml" = browser;
            "application/x-extension-htm" = browser;
            "application/x-extension-html" = browser;
            "application/x-extension-shtml" = browser;
            "application/x-extension-xht" = browser;
            "application/x-extension-xhtml" = browser;

            "x-scheme-handler/about" = browser;
            "x-scheme-handler/ftp" = browser;
            "x-scheme-handler/http" = browser;
            "x-scheme-handler/https" = browser;

            "inode/directory" = fileManager;

            "audio/*" = player;
            "video/*" = player;

            "image/*" = viewer;
            "image/gif" = viewer;
            "image/jpeg" = viewer;
            "image/png" = viewer;
            "image/webp" = viewer;
          };
        in
        {
          enable = true; # enable xdg base directories: XDG_CONFIG_HOME, XDG_STATE_HOME, XDG_CACHE_HOME, XDG_DATA_HOME
          mimeApps = {
            enable = true;
            defaultApplications = defaults;
            associations.added = defaults;
          };
          userDirs = {
            enable = true; # enable XDG user directories support
            createDirectories = true; # create standard user folders in $HOME
          };
        };
    };
  };
}
