{
  __findFile,
  constants,
  lib,
  inputs,
  paths,
  ...
}:
let
  inherit (import (paths.root + "/lib/secrets/sops/builders.nix") { inherit lib inputs paths; })
    mkNixosSops
    hostSopsFile
    ;
in
{
  den.aspects.secrets._.sops.provides = {
    vps = {
      includes = [ <secrets/sops> ];

      nixos = mkNixosSops {
        defaultSopsFile = hostSopsFile.vps;
        secrets = {
          "passwords/${constants.user.admin.username}" = {
            neededForUsers = true;
          };
        };
      };
    };
  };
}
