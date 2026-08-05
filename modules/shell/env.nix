{
  den.aspects.shell._.env.homeManager =
    { config, lib, ... }:
    let
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
