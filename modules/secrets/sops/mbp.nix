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
    mkDarwinSops
    sharedSopsFile
    hostSopsFile
    ;
in
{
  den.aspects.secrets._.sops.provides = {
    mbp = {
      includes = [ <secrets/sops> ];

      homeManager = mkHomeManagerSops {
        secrets = {
          "keys/ssh/github/signing/ghcny-pub" = {
            sopsFile = hostSopsFile.mbp;
          };
        };
      };

      nixos = mkNixosSops {
        defaultSopsFile = hostSopsFile.mbp;
        secrets = {
          "keys/ssh/workstation/users/${constants.user.chianyung.username}" = {
            sopsFile = sharedSopsFile;
          };
        };
      };

      darwin =
        args@{ config, pkgs, ... }:
        let
          userHome =
            config.users.users.${constants.user.chianyung.username}.home
              or "/Users/${constants.user.chianyung.username}";
        in
        mkDarwinSops {
          defaultSopsFile = hostSopsFile.mbp;
          extraPackages = [ pkgs.ssh-to-age ];
          age = {
            keyFile = "${userHome}/.local/share/ages/keys.txt";
            generateKey = true;
          };
          secrets = {
            "keys/ssh/github/auth/ghspy-pub" = {
              name = "ghspy-pub";
              sopsFile = sharedSopsFile;
              path = "${userHome}/.ssh_keys/ghspy.pub";
              owner = "${constants.user.chianyung.username}";
              mode = "0600";
            };

            "passwords/${constants.user.chianyung.username}" = {
              sopsFile = sharedSopsFile;
              neededForUsers = true;
            };
          };
        } args;
    };
  };
}
