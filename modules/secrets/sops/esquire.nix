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
    esquire = {
      includes = [ <secrets/sops> ];

      homeManager = mkHomeManagerSops {
        secrets = {
          "keys/ssh/github/signing/ghspy-pub" = {
            sopsFile = hostSopsFile.esquire;
          };
          "keys/pat/ghspy-pat" = {
            sopsFile = hostSopsFile.esquire;
          };
        };
      };
      nixos = mkNixosSops {
        defaultSopsFile = hostSopsFile.esquire;
        secrets = {
          "keys/ssh/github/auth/ghspy-pub" = {
            name = "ghspy-auth.pub";
            path = "/home/${constants.user.seraphynee.username}/.ssh_keys/ghspy-auth.pub";
            owner = "${constants.user.seraphynee.username}";
            mode = "0600";
          };
          "keys/ssh/github/auth/ghcny-pub" = {
            name = "ghcny-auth.pub";
            path = "/home/${constants.user.seraphynee.username}/.ssh_keys/ghcny-auth.pub";
            owner = "${constants.user.seraphynee.username}";
            mode = "0600";
          };
          "passwords/${constants.user.seraphynee.username}" = {
            sopsFile = sharedSopsFile;
            neededForUsers = true;
          };
          "keys/ssh/workstation/users/${constants.user.seraphynee.username}" = {
            sopsFile = sharedSopsFile;
          };
        };
      };
    };

  };
}
