{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatMapStringsSep
    escapeShellArgs
    hasPrefix
    mkIf
    mkOption
    splitString
    types
    ;

  cfg = config.dotnix.repositories;

  repositoryType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Human-readable unique repository name.";
      };

      url = mkOption {
        type = types.str;
        description = "Git clone URL. Credentials must not be embedded in this value.";
      };

      destination = mkOption {
        type = types.str;
        description = "Repository destination relative to the Home Manager user's home directory.";
      };
    };
  };

  isNormalizedRelativePath =
    path:
    path != ""
    && !hasPrefix "/" path
    && !hasPrefix "~" path
    && lib.all (component: component != "" && component != "." && component != "..") (
      splitString "/" path
    );

  allUnique = values: builtins.length values == builtins.length (lib.unique values);
  names = map (repository: repository.name) cfg.entries;
  destinations = map (repository: repository.destination) cfg.entries;

  syncCommands = concatMapStringsSep "\n" (
    repository:
    "sync_repository ${
      escapeShellArgs [
        repository.name
        repository.url
        repository.destination
      ]
    }"
  ) cfg.entries;

  reposSync = pkgs.writeShellApplication {
    name = "repos-sync";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.git
    ];
    text = ''
      : "''${HOME:?HOME must be set}"

      failed=0

      sync_repository() {
        local name="$1"
        local url="$2"
        local relative_destination="$3"
        local destination="$HOME/$relative_destination"

        if [[ -e "$destination/.git" ]]; then
          printf 'Fetching %s in %s\n' "$name" "$destination"
          if ! git -C "$destination" fetch --prune origin; then
            printf 'Failed to fetch %s\n' "$name" >&2
            failed=1
          fi
          return
        fi

        if [[ -e "$destination" ]]; then
          printf 'Refusing to overwrite non-Git path for %s: %s\n' "$name" "$destination" >&2
          failed=1
          return
        fi

        printf 'Cloning %s into %s\n' "$name" "$destination"
        mkdir -p -- "$(dirname -- "$destination")"
        if ! git clone -- "$url" "$destination"; then
          printf 'Failed to clone %s\n' "$name" >&2
          failed=1
        fi
      }

      ${syncCommands}

      if (( failed != 0 )); then
        printf 'One or more repositories failed to synchronize.\n' >&2
        exit 1
      fi

      printf 'Repository synchronization complete (%d configured).\n' ${toString (builtins.length cfg.entries)}
    '';
  };
in
{
  options.dotnix.repositories = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install the repos-sync CLI without running network operations during activation.";
    };

    entries = mkOption {
      type = types.listOf repositoryType;
      default = [ ];
      description = "Repositories cloned or fetched by the manually invoked repos-sync CLI.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = allUnique names;
        message = "dotnix.repositories.entries must use unique repository names";
      }
      {
        assertion = allUnique destinations;
        message = "dotnix.repositories.entries must use unique destinations";
      }
    ]
    ++ lib.concatMap (repository: [
      {
        assertion = repository.name != "";
        message = "dotnix.repositories.entries contains an empty repository name";
      }
      {
        assertion = repository.url != "";
        message = "dotnix.repositories entry `${repository.name}` must use a non-empty URL";
      }
      {
        assertion = isNormalizedRelativePath repository.destination;
        message = "dotnix.repositories entry `${repository.name}` destination must be a normalized path relative to HOME";
      }
    ]) cfg.entries;

    home.packages = [ reposSync ];
  };
}
