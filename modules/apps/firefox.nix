{ __findFile, ... }:
{
  den.aspects.apps._.firefox.homeManager = {
    programs.firefox = {
      enable = true;
      profiles.default = {
        settings = {
          "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
        };
      };
    };
  };
}
