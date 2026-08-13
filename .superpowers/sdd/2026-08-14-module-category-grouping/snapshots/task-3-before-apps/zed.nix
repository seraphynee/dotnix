{ __findFile, ... }:
{
  den.aspects.apps._.zed = {
    homeManager =
      { config, pkgs, ... }:
      let
        staticSettings = builtins.readFile ../../dots/config/zed/settings.json;
        hasWakatimeSecret = config.sops.secrets ? "productivity/wakatime_apikey";
        settings =
          if hasWakatimeSecret then
            builtins.replaceStrings
              [ "    \"nil\": {" ]
              [
                (
                  ''
                    "wakatime": {
                      "initialization_options": {
                        "api-key": "${config.sops.placeholder."productivity/wakatime_apikey"}"
                      }
                    },
                  ''
                  + ''"nil": {''
                )
              ]
              staticSettings
          else
            staticSettings;
      in
      {
        home.packages = [ pkgs.zed-editor ];

        xdg.configFile = {
          "zed/keymap.json".source = ../../dots/config/zed/keymap.json;
          "zed/tasks.json".source = ../../dots/config/zed/tasks.json;
        };

        sops.templates."zed-settings.json" = {
          path = "${config.xdg.configHome}/zed/settings.json";
          mode = "0600";
          content = settings;
        };
      };
  };
}
