{ __findFile, lib, ... }:
{
  # Bash
  den.aspects.shell._.bash = {
    homeManager = {
      programs.bash = {
        enable = true;
        enableCompletion = true;
        # TODO add your custom bashrc here
        bashrcExtra = ''
          export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"
        '';

        # set some aliases, feel free to add more or remove some
        shellAliases = {
          k = "kubectl";
          urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
          urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
        };
      };
    };
  };
  # Shared environment
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
  # Fish
  den.aspects.shell._.fish.homeManager =
    { pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
      clipboardCommand =
        if isDarwin then
          "pbcopy"
        else if isLinux then
          "wl-copy"
        else
          "";

      commonAliases =
        if isDarwin then
          ''
            function cpwd
                if not command -q ${clipboardCommand}
                    echo "cpwd: ${clipboardCommand} is not available" >&2
                    return 1
                end
                printf '%s' "$PWD" | ${clipboardCommand}
            end

            # === DARWIN ===
            alias caff="caffeinate -ism"           # Run command without letting mac sleep

            alias showdot='defaults write com.apple.finder AppleShowAllFiles TRUE'  # show dot files in Finder
            alias hidedot='defaults write com.apple.finder AppleShowAllFiles FALSE' # hide dot files in Finder
            alias spot-off="sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist"
            alias spot-on="sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist"
            alias fixmounts="sudo automount -vcu" # Re-mount all shared drives
          ''
        else if isLinux then
          ''
            function cpwd
                if not command -q ${clipboardCommand}
                    echo "cpwd: ${clipboardCommand} is not available" >&2
                    return 1
                end
                printf '%s' "$PWD" | ${clipboardCommand}
            end

            # === LINUX ===
            alias ctl='systemctl'
            alias reboot="sudo systemctl reboot"
            alias sstop="sudo systemctl stop"
            alias sstatus="sudo systemctl status"

            # Start and then view status of service
            function sstart
                sudo systemctl start $argv[1]
                sudo systemctl status $argv[1]
            end

            # Restart and then view status of service
            function srestart
                sudo systemctl restart $argv[1]
                sudo systemctl status $argv[1]
            end

            # Journalctl aliases
            alias logs='sudo journalctl -fu'
            alias logs-all='sudo journalctl -u'
          ''
        else
          "";

      commonAliasesFish = builtins.replaceStrings [ "@common_aliases@" ] [ commonAliases ] (
        builtins.readFile ../../dots/config/fish/conf.d/common_aliases.fish
      );
    in
    {
      # home.packages = [ pkgs.fish ];

      xdg.configFile."fish/fish_plugins".source = ../../dots/config/fish/fish_plugins;
      xdg.configFile."fish/conf.d/colors.fish".source = ../../dots/config/fish/conf.d/colors.fish;
      xdg.configFile."fish/conf.d/atuin.fish".source = ../../dots/config/fish/conf.d/atuin.fish;
      xdg.configFile."fish/conf.d/bat.fish".source = ../../dots/config/fish/conf.d/bat.fish;
      xdg.configFile."fish/conf.d/common_functions.fish".source =
        ../../dots/config/fish/conf.d/common_functions.fish;
      xdg.configFile."fish/conf.d/common_aliases.fish" = {
        text = commonAliasesFish;
      };
      xdg.configFile."fish/conf.d/chezmoi.fish".source = ../../dots/config/fish/conf.d/chezmoi.fish;
      xdg.configFile."fish/conf.d/abbreviations.fish".source =
        ../../dots/config/fish/conf.d/abbreviations.fish;
      xdg.configFile."fish/conf.d/jujutsu.fish".source = ../../dots/config/fish/conf.d/jujutsu.fish;
      xdg.configFile."fish/conf.d/yazi.fish".source = ../../dots/config/fish/conf.d/yazi.fish;
      xdg.configFile."fish/conf.d/pet.fish".source = ../../dots/config/fish/conf.d/pet.fish;
      xdg.configFile."fish/conf.d/sk-git.fish".source = ../../dots/config/fish/conf.d/sk-git.fish;
      xdg.configFile."fish/conf.d/skim.fish".source = ../../dots/config/fish/conf.d/skim.fish;
      xdg.configFile."fish/conf.d/zoxide.fish".source = ../../dots/config/fish/conf.d/zoxide.fish;
      xdg.configFile."fish/completions/just.fish".text = ''
        command just --completions fish | source
      '';

      programs = {
        command-not-found.enable = false;
        nix-index-database.comma.enable = false;

        fish = {
          enable = true;
          interactiveShellInit = ''
            set -g fish_greeting
            abbr --add cl clear
            fish_vi_key_bindings

            # === sesh binding ===
            # Untuk default mode (emacs mode)
            bind \eu 'sesh-connect-picker'

            # Untuk vi mode jika diaktifkan
            bind -M insert \eu 'sesh-connect-picker'
            bind -M default \eu 'sesh-connect-picker'

          '';
          plugins = [
            {
              name = "fisher";
              src = pkgs.fetchFromGitHub {
                owner = "jorgebucaran";
                repo = "fisher";
                rev = "791da644d33d392216f6b1a9b5fc1e470db6d7f2";
                hash = "sha256-U1yd8m56YrHXrJFkU8xaOglulOGV0iBvwjU/bdf8tqA=";
              };
            }
          ];
          functions = {
            tmux = ''
              if test (count $argv) -eq 0
                  set -l dir (basename "$PWD")
                  set -l session (string replace -ra '[^A-Za-z0-9_.-]' '_' -- $dir)
                  test -n "$session"; or set session main

                  if set -q TMUX
                      if command tmux has-session -t "$session" 2>/dev/null
                          command tmux switch-client -t "$session"
                      else
                          command tmux new-session -d -s "$session" -c "$PWD"
                          command tmux switch-client -t "$session"
                      end
                  else
                      command tmux new-session -A -s "$session" -c "$PWD"
                  end
                  return
              end

              command tmux $argv
            '';
          };
          # interactiveShellInit = ''
          #   ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
          # '';
        };
      };
    };
  # Zsh
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
      xdg.configFile."zsh-abbr/user-abbreviations".source = ../../dots/config/zsh-abbr/user-abbreviations;
    };
}
