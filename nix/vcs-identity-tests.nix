{
  inputs,
  lib,
  ...
}:
{
  perSystem =
    {
      pkgs,
      ...
    }:
    let
      mkProfileHome =
        profile:
        lib.evalModules {
          modules = [
            {
              options.assertions = lib.mkOption {
                type = lib.types.listOf lib.types.attrs;
                default = [ ];
              };
            }
            ../lib/shell/vcs/profile.nix
            {
              dotnix.vcs = profile;
            }
          ];
        };

      mkVcsHome =
        profile:
        inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ../lib/shell/vcs/profile.nix
            ../lib/shell/vcs/git.nix
            {
              home = {
                username = "vcs-test";
                homeDirectory = if pkgs.stdenv.isDarwin then "/Users/vcs-test" else "/home/vcs-test";
                stateVersion = "26.11";
              };
              dotnix.vcs = profile;
            }
          ];
        };

      assertionsPass = home: lib.all (entry: entry.assertion) home.config.assertions;

      valid = mkProfileHome {
        identity = {
          name = "alpha";
          email = "alpha@example.test";
        };
        git.enable = true;
      };

      missingName = mkProfileHome {
        identity.email = "missing-name@example.test";
        git.enable = true;
      };

      missingEmail = mkProfileHome {
        identity.name = "missing-email";
        jujutsu.enable = true;
      };

      seraphyne = mkVcsHome {
        identity = {
          name = "seraphynee";
          email = "seraphyne31@gmail.com";
        };
        github.username = "seraphynee";
        git.enable = true;
      };

      chianyung = mkVcsHome {
        identity = {
          name = "chianyungcode";
          email = "cnytechcode@gmail.com";
        };
        github.username = "chianyungcode";
        git.enable = true;
      };
    in
    {
      checks.vcs-identity =
        assert valid.config.dotnix.vcs.identity.name == "alpha";
        assert valid.config.dotnix.vcs.identity.email == "alpha@example.test";
        assert assertionsPass valid;
        assert !assertionsPass missingName;
        assert !assertionsPass missingEmail;
        assert assertionsPass seraphyne;
        assert assertionsPass chianyung;
        assert
          seraphyne.config.programs.git.settings.user == {
            name = "seraphynee";
            email = "seraphyne31@gmail.com";
          };
        assert
          chianyung.config.programs.git.settings.user == {
            name = "chianyungcode";
            email = "cnytechcode@gmail.com";
          };
        assert seraphyne.config.programs.git.settings.user != chianyung.config.programs.git.settings.user;
        assert
          seraphyne.config.programs.git.settings.credential."https://github.com".username == "seraphynee";
        assert seraphyne.config.programs.git.settings.alias.co == "checkout";
        pkgs.runCommand "vcs-identity-evaluation" { } ''
          touch "$out"
        '';
    };
}
