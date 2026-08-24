{ lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      repositoryFixture = pkgs.runCommand "repos-sync-fixture" { nativeBuildInputs = [ pkgs.git ]; } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME" work

        git init --bare "$out"
        git -C work init
        git -C work config user.name "Repository Sync Test"
        git -C work config user.email "repos-sync@example.test"
        printf 'fixture\n' > work/README.md
        git -C work add README.md
        git -C work commit -m "Initial fixture"
        git -C work push "$out" HEAD:refs/heads/main
        git --git-dir="$out" symbolic-ref HEAD refs/heads/main
      '';

      mkRepositoriesConfiguration =
        entries:
        lib.evalModules {
          specialArgs = { inherit pkgs; };
          modules = [
            {
              options = {
                assertions = lib.mkOption {
                  type = lib.types.listOf lib.types.attrs;
                  default = [ ];
                };
                home.packages = lib.mkOption {
                  type = lib.types.listOf lib.types.package;
                  default = [ ];
                };
              };
            }
            ../../lib/shell/vcs/repositories.nix
            {
              dotnix.repositories = {
                enable = true;
                inherit entries;
              };
            }
          ];
        };

      assertionsPass = configuration: lib.all (entry: entry.assertion) configuration.config.assertions;

      valid = mkRepositoriesConfiguration [
        {
          name = "fixture";
          url = "file://${repositoryFixture}";
          destination = "Code/Personal/Projects/fixture";
        }
      ];

      invalidDestination = mkRepositoriesConfiguration [
        {
          name = "absolute";
          url = "file://${repositoryFixture}";
          destination = "/tmp/absolute";
        }
      ];

      duplicateDestination = mkRepositoriesConfiguration [
        {
          name = "first";
          url = "file://${repositoryFixture}";
          destination = "Code/duplicate";
        }
        {
          name = "second";
          url = "file://${repositoryFixture}";
          destination = "Code/duplicate";
        }
      ];

      reposSyncPackages = builtins.filter (
        package: lib.getName package == "repos-sync"
      ) valid.config.home.packages;
      reposSync = builtins.head reposSyncPackages;
    in
    {
      checks.repositories-sync =
        assert assertionsPass valid;
        assert !assertionsPass invalidDestination;
        assert !assertionsPass duplicateDestination;
        assert builtins.length reposSyncPackages == 1;
        pkgs.runCommand "repositories-sync-tests" { } ''
          export HOME="$TMPDIR/home"
          mkdir -p "$HOME"

          ${lib.getExe reposSync}
          test -e "$HOME/Code/Personal/Projects/fixture/.git"
          test "$(< "$HOME/Code/Personal/Projects/fixture/README.md")" = fixture

          ${lib.getExe reposSync}

          touch "$out"
        '';
    };
}
