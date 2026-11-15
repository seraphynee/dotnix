{ lib, paths, ... }:
{
  # The user-shell battery enables system-wide programs.zsh on NixOS, whose
  # /etc/zshrc would otherwise run its own compinit before ~/.zshrc. Home
  # Manager (below) owns the single, cached compinit instead.
  den.aspects.shell._.zsh.nixos.programs.zsh.enableGlobalCompInit = false;

  den.aspects.shell._.zsh.homeManager =
    { config, pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) isDarwin;
      zcompdump = "${config.xdg.cacheHome}/zsh/zcompdump-$ZSH_VERSION";
      zshConfig = paths.dots + "/config/zsh";
      sourceConfD = ''
        setopt extendedglob null_glob
        for file in "${config.xdg.configHome}/zsh/conf.d"/**/*.(zsh|sh)(N); do
          [[ -r "$file" ]] && source "$file"
        done
      '';
    in
    {
      programs.zsh = {
        enable = true;

        # Skip the system-wide /etc/zshrc on nix-darwin: it runs an uncached
        # compinit (plus compaudit, promptinit and bashcompinit) before
        # ~/.zshrc, which already sets up completion once, below.
        envExtra = lib.mkIf isDarwin ''
          NOSYSZSHRC=1
        '';

        # compinit is deferred until after conf.d is sourced (see initContent
        # mkOrder 1010) so every fpath addition lands in the dump. Until then,
        # `compdef` calls are queued and replayed afterwards.
        completionInit = ''
          typeset -ga __compdef_queue
          compdef() { __compdef_queue+=("''${(j: :)''${(@q)@}}") }
        '';

        initContent = lib.mkMerge [
          (lib.mkOrder 1000 ''
            export ZDOTDIR="${config.home.homeDirectory}"
            for file in "${config.xdg.configHome}/zsh/env.d"/*.sh(N); do [[ -r "$file" ]] && source "$file"; done
            if [[ -r "${pkgs.zsh-abbr}/share/zsh-abbr/zsh-abbr.zsh" ]]; then
              source "${pkgs.zsh-abbr}/share/zsh-abbr/zsh-abbr.zsh"
            elif [[ -r "${pkgs.zsh-abbr}/share/zsh-abbr/zsh-abbr.plugin.zsh" ]]; then
              source "${pkgs.zsh-abbr}/share/zsh-abbr/zsh-abbr.plugin.zsh"
            fi
            ${sourceConfD}
            if (( $+commands[abbr] )) && [[ -r "${config.xdg.configHome}/zsh-abbr/user-abbreviations" ]]; then
              source "${config.xdg.configHome}/zsh-abbr/user-abbreviations"
            fi
          '')

          # Real compinit, after conf.d. A full check (new functions plus
          # compaudit) runs at most once a day, otherwise the dump is trusted.
          (lib.mkOrder 1010 ''
            autoload -Uz compinit
            zcdump="${zcompdump}"
            [[ -d ''${zcdump:h} ]] || mkdir -p -- ''${zcdump:h}
            () {
              local -a fresh=($zcdump(N.mh-24))
              if (( $#fresh )); then
                compinit -C -d "$zcdump"
              else
                compinit -d "$zcdump" && touch "$zcdump"
              fi
            }

            # Compile in the background; zsh picks up the .zwc on the next start.
            if [[ ! -s "''${zcdump}.zwc" || "$zcdump" -nt "''${zcdump}.zwc" ]]; then
              zcompile "$zcdump" &!
            fi

            # Replay compdef calls queued before compinit.
            () {
              local def
              for def in $__compdef_queue; do
                eval "compdef $def"
              done
            }
            unset __compdef_queue zcdump
          '')
        ];
      };

      home.packages = [ pkgs.zsh-abbr ];
      xdg.configFile."zsh/conf.d/002-options.bash".source = zshConfig + "/conf.d/002-options.bash";
      xdg.configFile."zsh/conf.d/002-options.zsh".source = zshConfig + "/conf.d/002-options.zsh";
      xdg.configFile."zsh/conf.d/060-common-aliases.sh".source =
        zshConfig + "/conf.d/060-common-aliases.sh";
      xdg.configFile."zsh/conf.d/060-common-functions.sh".source =
        zshConfig + "/conf.d/060-common-functions.sh";
      # recursive: other modules (e.g. herdr) add files under third-party/, which
      # a single directory symlink into the read-only store would shadow.
      xdg.configFile."zsh/conf.d/third-party" = {
        source = zshConfig + "/conf.d/third-party";
        recursive = true;
      };
      xdg.configFile."zsh-abbr/user-abbreviations".source =
        paths.dots + "/config/zsh-abbr/user-abbreviations";
    };
}
