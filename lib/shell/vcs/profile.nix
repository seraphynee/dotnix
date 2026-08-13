{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.dotnix.vcs;
  vcsEnabled = cfg.git.enable || cfg.jujutsu.enable;
  nonEmpty = value: value != null && value != "";
in
{
  options.dotnix.vcs = {
    identity = {
      name = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Commit author name shared by Git and Jujutsu.";
      };
      email = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Commit author email shared by Git and Jujutsu.";
      };
    };

    github = {
      username = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "GitHub account name, independent from commit author identity.";
      };
      patSecret = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "sops-nix secret name containing the GitHub personal access token.";
      };
    };

    signing.keySecret = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "sops-nix secret name containing the shared SSH signing public key.";
    };

    git.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable the shared Git configuration.";
    };

    jujutsu = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the shared Jujutsu configuration.";
      };
      bookmarkPrefix = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Explicit prefix for generated Jujutsu push bookmarks.";
      };
      workstation = mkOption {
        type = types.bool;
        default = false;
        description = "Enable workstation-only Jujutsu diff tooling.";
      };
    };
  };

  config.assertions = lib.optionals vcsEnabled [
    {
      assertion = nonEmpty cfg.identity.name;
      message = "dotnix.vcs.identity.name must be non-empty when Git or Jujutsu is enabled";
    }
    {
      assertion = nonEmpty cfg.identity.email;
      message = "dotnix.vcs.identity.email must be non-empty when Git or Jujutsu is enabled";
    }
  ];
}
