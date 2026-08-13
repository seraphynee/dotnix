{
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
    in
    {
      checks.vcs-identity =
        assert valid.config.dotnix.vcs.identity.name == "alpha";
        assert valid.config.dotnix.vcs.identity.email == "alpha@example.test";
        assert assertionsPass valid;
        assert !assertionsPass missingName;
        assert !assertionsPass missingEmail;
        pkgs.runCommand "vcs-identity-evaluation" { } ''
          touch "$out"
        '';
    };
}
