{ __findFile, lib, ... }:
{
  den.aspects.shell._.espanso = {
    nixos =
      { pkgs, ... }:
      {
        services.espanso = {
          enable = true;
          package = pkgs.espanso-wayland;
        };
      };

    homeManager =
      { config, ... }:
      let
        espansoSecrets = lib.filterAttrs (name: _: lib.hasPrefix "espanso/" name) config.sops.secrets;
      in
      {
        # Keep espanso runtime under the NixOS module on Wayland so the
        # capability wrapper is applied correctly. Espanso match files remain
        # user-scoped and can safely be wired from decrypted sops secrets.
        xdg.configFile = lib.mapAttrs' (
          name: secret:
          let
            fileName = lib.removePrefix "espanso/" name;
            targetName =
              if lib.hasSuffix ".yml" fileName || lib.hasSuffix ".yaml" fileName then
                fileName
              else
                "${fileName}.yml";
          in
          lib.nameValuePair "espanso/match/${targetName}" {
            source = config.lib.file.mkOutOfStoreSymlink secret.path;
          }
        ) espansoSecrets;
      };
  };
}
