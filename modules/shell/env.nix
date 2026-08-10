{
  den.aspects.shell._.env.homeManager =
    { config, lib, ... }:
    let
      runtimeSecretNames = {
        CONTEXT7_MCP_API_KEY = "llm/context7_apikey";
        OPENROUTER_API_KEY = "llm/openrouter_apikey";
        WAKATIME_API_KEY = "productivity/wakatime_apikey";
      };

      configuredSopsSecrets = lib.attrByPath [ "sops" "secrets" ] { } config;

      runtimeSecretPaths =
        lib.mapAttrs (_variable: secretName: configuredSopsSecrets.${secretName}.path)
          (
            lib.filterAttrs (
              _variable: secretName: builtins.hasAttr secretName configuredSopsSecrets
            ) runtimeSecretNames
          );

      fishRuntimeSecretAssignments = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (variable: path: ''
          if test -r ${lib.escapeShellArg path}
              set -gx ${variable} (command cat -- ${lib.escapeShellArg path})
          end
        '') runtimeSecretPaths
      );

      fishRuntimeSecretInit = ''
        # BEGIN dotnix runtime secrets
        ${fishRuntimeSecretAssignments}
        if set -q GITHUB_TOKEN_FILE; and test -r "$GITHUB_TOKEN_FILE"
            set -gx GITHUB_TOKEN (command cat -- "$GITHUB_TOKEN_FILE")
        end
        # END dotnix runtime secrets
      '';

      zshRuntimeSecretAssignments = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (variable: path: ''
          if [[ -r ${lib.escapeShellArg path} ]]; then
              export ${variable}="$(< ${lib.escapeShellArg path})"
          fi
        '') runtimeSecretPaths
      );

      zshRuntimeSecretInit = ''
        # BEGIN dotnix runtime secrets
        ${zshRuntimeSecretAssignments}
        if [[ -n ''${GITHUB_TOKEN_FILE:-} && -r "$GITHUB_TOKEN_FILE" ]]; then
            export GITHUB_TOKEN="$(< "$GITHUB_TOKEN_FILE")"
        fi
        # END dotnix runtime secrets
      '';

      userDirs = {
        DESKTOP = config.xdg.userDirs.desktop;
        DOCUMENTS = config.xdg.userDirs.documents;
        DOWNLOAD = config.xdg.userDirs.download;
        MUSIC = config.xdg.userDirs.music;
        PICTURES = config.xdg.userDirs.pictures;
        PUBLICSHARE = config.xdg.userDirs.publicShare;
        TEMPLATES = config.xdg.userDirs.templates;
        VIDEOS = config.xdg.userDirs.videos;
      };

      userDirAssignments = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: value:
          lib.optionalString (value != null) "set -gx XDG_${name}_DIR ${lib.escapeShellArg value}"
        ) userDirs
      );

      userDirAssignmentsZsh = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: value: lib.optionalString (value != null) "export XDG_${name}_DIR=${lib.escapeShellArg value}"
        ) userDirs
      );

      userDirExports = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: _: ''
          set -l xdg_${lib.toLower name}_dir (xdg-user-dir ${name})
          if test -n "$xdg_${lib.toLower name}_dir"
              set -gx XDG_${name}_DIR "$xdg_${lib.toLower name}_dir"
          end'') userDirs
      );

      render =
        file: replacements:
        builtins.replaceStrings (builtins.attrNames replacements) (builtins.attrValues replacements) (
          builtins.readFile file
        );
    in
    {
      programs.fish.interactiveShellInit = lib.mkBefore fishRuntimeSecretInit;
      programs.zsh.initContent = lib.mkBefore zshRuntimeSecretInit;

      xdg.configFile."fish/env.d/000-xdg.fish".text = render ../../dots/config/fish/env.d/000-xdg.fish {
        "@XDG_DATA_HOME@" = lib.escapeShellArg config.xdg.dataHome;
        "@XDG_CONFIG_HOME@" = lib.escapeShellArg config.xdg.configHome;
        "@XDG_STATE_HOME@" = lib.escapeShellArg config.xdg.stateHome;
        "@XDG_CACHE_HOME@" = lib.escapeShellArg config.xdg.cacheHome;
        "# @XDG_USER_DIR_ASSIGNMENTS@" = userDirAssignments;
        "# @XDG_USER_DIR_EXPORTS@" = userDirExports;
      };

      xdg.configFile."zsh/env.d/000-xdg.sh".text = render ../../dots/config/zsh/env.d/000-xdg.sh {
        "@XDG_DATA_HOME@" = lib.escapeShellArg config.xdg.dataHome;
        "@XDG_CONFIG_HOME@" = lib.escapeShellArg config.xdg.configHome;
        "@XDG_STATE_HOME@" = lib.escapeShellArg config.xdg.stateHome;
        "@XDG_CACHE_HOME@" = lib.escapeShellArg config.xdg.cacheHome;
        "# @XDG_USER_DIR_ASSIGNMENTS@" = userDirAssignmentsZsh;
      };
    };

  den.aspects.shell._.env.nixos = {
    environment.variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };
}
