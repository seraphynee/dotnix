{
  inputs,
  lib,
  constants,
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
            ../../lib/shell/vcs/profile.nix
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
            ../../lib/shell/vcs/profile.nix
            ../../lib/shell/vcs/git.nix
            ../../lib/shell/vcs/jujutsu.nix
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
          name = constants.user.seraphynee.git_user;
          email = constants.user.seraphynee.email;
        };
        github.username = constants.user.seraphynee.git_user;
        git.enable = true;
        jujutsu = {
          enable = true;
          workstation = true;
        };
      };

      chianyung = mkVcsHome {
        identity = {
          name = constants.user.chianyung.git_user;
          email = constants.user.chianyung.email;
        };
        github.username = constants.user.chianyung.git_user;
        git.enable = true;
      };

      explicitPrefix = mkVcsHome {
        identity = {
          name = "author-name";
          email = "author@example.test";
        };
        github.username = "forge-name";
        jujutsu = {
          enable = true;
          bookmarkPrefix = "custom-prefix";
        };
      };
    in
    {
      checks.vcs-identity =
        assert
          constants.user.chianyung == {
            username = "chianyung";
            git_user = "chianyungcode";
            email = "cnytechcode@gmail.com";
          };
        assert
          constants.user.seraphynee == {
            username = "seraphynee";
            git_user = "seraphynee";
            email = "seraphyne31@gmail.com";
          };
        assert
          constants.user.micha == {
            username = "micha";
            git_user = null;
            email = null;
          };
        assert
          constants.user.admin == {
            username = "admin";
            git_user = null;
            email = null;
          };
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
        assert
          seraphyne.config.programs.jujutsu.settings.user == seraphyne.config.programs.git.settings.user;
        assert
          seraphyne.config.programs.jujutsu.settings.templates.git_push_bookmark
          == ''"seraphynee/push-" ++ change_id.short()'';
        assert
          seraphyne.config.programs.jujutsu.settings.ui."diff-formatter" == [
            "difft"
            "--color=always"
            "$left"
            "$right"
          ];
        assert !chianyung.config.programs.jujutsu.enable;
        assert
          explicitPrefix.config.programs.jujutsu.settings.templates.git_push_bookmark
          == ''"custom-prefix/push-" ++ change_id.short()'';
        pkgs.runCommand "vcs-identity-evaluation" { } ''
          touch "$out"
        '';
    };
}
