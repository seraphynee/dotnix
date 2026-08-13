{ __findFile, ... }:
{
  den.aspects.apps._.firefox = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          google-chrome
          slack
        ];
      };
    homeManager = {
      programs.firefox = {
        enable = true;
        profiles.default = {
          settings = {
            "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
          };
        };
      };
    };
  };
}
