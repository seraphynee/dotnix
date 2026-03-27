{
  den.aspects.shell._.opencommit = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ opencommit ];
      };
    homeManager =
      { config, pkgs, ... }:
      let
        ocoConfig =
          builtins.replaceStrings
            [
              "@oco_api_key@"
              "@oco_api_url@"
            ]
            [
              config.sops.placeholder."llm/oco_api_key"
              config.sops.placeholder."llm/oco_api_url"
            ]
            (builtins.readFile ../../dots/opencommit.tmpl);
      in
      {
        sops.templates."opencommit-config" = {
          path = "${config.home.homeDirectory}/.opencommit";
          mode = "0600";
          content = ocoConfig;
        };
      };
  };
}
