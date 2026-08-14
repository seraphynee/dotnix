_: {
  den.aspects.system._.fonts.nixos =
    { pkgs, ... }:
    {
      fonts = {
        fontconfig = {
          enable = true;
          subpixel.rgba = "rgb";
          hinting.enable = true;
          hinting.style = "slight";
          antialias = true;

          defaultFonts = {
            serif = [
              "Noto Serif"
              "Liberation Serif"
            ];
            sansSerif = [
              "Noto Sans"
              "Liberation Sans"
            ];
            monospace = [
              "JetBrains Mono"
              "Liberation Mono"
            ];
            emoji = [ "Noto Color Emoji" ];
          };
        };

        packages = with pkgs; [
          # Nerd Fonts
          nerd-fonts.fira-code
          nerd-fonts.atkynson-mono
          nerd-fonts.caskaydia-cove
          nerd-fonts.caskaydia-mono
          nerd-fonts.hack
          nerd-fonts.iosevka
          nerd-fonts.jetbrains-mono

          # System fonts
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-color-emoji
          liberation_ttf

          # Programming fonts
          jetbrains-mono
          fira-code
          source-code-pro

          # Popular fonts
          roboto
          open-sans
          ubuntu-classic
          martian-mono
          _0xproto
          geist-font
          monaspace
          hack-font

          # Icon fonts
          font-awesome
        ];
      };
    };

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

        # Mango is launched directly by SDDM and does not activate
        # graphical-session.target. xdg-desktop-portal 1.22 otherwise refuses
        # to start because its upstream unit requires that target to be active.
        systemd.user.services.xdg-desktop-portal = {
          overrideStrategy = "asDropin";
          unitConfig.Requisite = "";
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
