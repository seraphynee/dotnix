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
    mkHomeManagerSops
    mkNixosSops
    sharedSopsFile
    hostSopsFile
    ;
in
{
  den.aspects.secrets._.sops.provides = {
    acerus = {
      includes = [ <secrets/sops> ];

      homeManager = mkHomeManagerSops {
        secrets = {
          "keys/ssh/github/signing/ghspy-pub" = {
            sopsFile = hostSopsFile.acerus;
          };
        };
      };

      nixos = mkNixosSops {
        defaultSopsFile = hostSopsFile.acerus;
        secrets = {
          "keys/ssh/github/auth/ghspy-pub" = {
            name = "ghspy-auth.pub";
            path = "/home/${constants.user.seraphynee.username}/.ssh_keys/ghspy-auth.pub";
            owner = "${constants.user.seraphynee.username}";
            mode = "0600";
          };
          "passwords/${constants.user.seraphynee.username}" = {
            sopsFile = sharedSopsFile;
            neededForUsers = true;
          };
          "passwords/${constants.user.micha.username}" = {
            sopsFile = sharedSopsFile;
            neededForUsers = true;
          };
          "keys/ssh/workstation/users/${constants.user.seraphynee.username}" = {
            sopsFile = sharedSopsFile;
          };
          "keys/ssh/workstation/users/${constants.user.micha.username}" = {
            sopsFile = sharedSopsFile;
          };
        };
      };
    };

  };
}
