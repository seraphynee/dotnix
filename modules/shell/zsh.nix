{
  __findFile,
  lib,
  ...
}:
{
  den.aspects.shell._.zsh.homeManager =
    { config, pkgs, ... }:
    let
      zshConfig = ../../dots/config/zsh;
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
        initContent = lib.mkOrder 1000 ''
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
        '';
      };

      home.packages = [ pkgs.zsh-abbr ];
      xdg.configFile."zsh/conf.d/002-options.bash".source = zshConfig + "/conf.d/002-options.bash";
      xdg.configFile."zsh/conf.d/002-options.zsh".source = zshConfig + "/conf.d/002-options.zsh";
      xdg.configFile."zsh/conf.d/060-common-aliases.sh".source =
        zshConfig + "/conf.d/060-common-aliases.sh";
      xdg.configFile."zsh/conf.d/060-common-functions.sh".source =
        zshConfig + "/conf.d/060-common-functions.sh";
      xdg.configFile."zsh/conf.d/090-personal.sh".source = zshConfig + "/conf.d/090-personal.sh";
      xdg.configFile."zsh/conf.d/third-party".source = zshConfig + "/conf.d/third-party";
      xdg.configFile."zsh/.zshrc.bak".source = zshConfig + "/.zshrc.bak";
      xdg.configFile."zsh-abbr/user-abbreviations".source = ../../dots/config/zsh-abbr/user-abbreviations;
    };
}
