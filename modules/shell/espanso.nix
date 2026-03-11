{ __findFile, lib, ... }:
{
  den.aspects.shell._.espanso = {
    homeManager =
      { config, ... }:
      let
        espansoSecrets = lib.filterAttrs (name: _: lib.hasPrefix "espanso/" name) config.sops.secrets;
      in
      {
        xdg.configFile = lib.mapAttrs' (
          name: secret:
          let
            fileName = lib.removePrefix "espanso/" name;
          in
          lib.nameValuePair "espanso/match/${fileName}.yaml" {
            source = config.lib.file.mkOutOfStoreSymlink secret.path;
          }
        ) espansoSecrets;

        services = {
          espanso.enable = true;
        };
      };
  };
}
