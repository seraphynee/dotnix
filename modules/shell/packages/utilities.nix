_: {
  den.aspects.shell._.utils.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      zoxideFishInit = pkgs.runCommand "zoxide-fish-init.fish" { } ''
        ${lib.getExe config.programs.zoxide.package} init fish ${lib.escapeShellArgs config.programs.zoxide.options} > "$out"
      '';
      direnvFishHook = pkgs.runCommand "direnv-fish-hook.fish" { } ''
        ${lib.getExe config.programs.direnv.package} hook fish > "$out"
      '';
      # Generate the Devenv Fish integration during the Nix build, not at shell startup.
      devenvFishHook =
        pkgs.runCommand "devenv-fish-hook.fish"
          {
            nativeBuildInputs = [ pkgs.writableTmpDirAsHomeHook ];
          }
          ''
            ${lib.getExe config.programs.devenv.package} hook fish > "$out"
          '';
      devenvZshHook =
        pkgs.runCommand "devenv-zsh-hook.zsh"
          {
            nativeBuildInputs = [ pkgs.writableTmpDirAsHomeHook ];
          }
          ''
            ${lib.getExe config.programs.devenv.package} hook zsh > "$out"
          '';
      zoxideZshInit = pkgs.runCommand "zoxide-zsh-init.zsh" { } ''
        ${lib.getExe config.programs.zoxide.package} init zsh ${lib.escapeShellArgs config.programs.zoxide.options} > "$out"
      '';
      direnvZshHook = pkgs.runCommand "direnv-zsh-hook.zsh" { } ''
        ${lib.getExe config.programs.direnv.package} hook zsh > "$out"
      '';
      # Generate `atuin init` during the Nix build instead of spawning atuin
      # at every shell start. HOME is writable because atuin creates its
      # config/data directories on any invocation.
      atuinInit =
        shell:
        pkgs.runCommand "atuin-${shell}-init" { nativeBuildInputs = [ pkgs.writableTmpDirAsHomeHook ]; } ''
          ${lib.getExe config.programs.atuin.package} init ${shell} ${lib.escapeShellArgs config.programs.atuin.flags} > "$out"
        '';
      atuinFishInit = atuinInit "fish";
      atuinZshInit = atuinInit "zsh";
    in
    {
      # The user snippet also shadows direnv's vendor snippet, which otherwise
      # invokes `direnv hook fish` before interactiveShellInit runs.
      xdg.configFile."fish/conf.d/direnv.fish" =
        lib.mkIf (config.programs.fish.enable && config.programs.direnv.enable)
          {
            source = direnvFishHook;
          };
      services.ssh-agent = {
        enable = true;
      };

      programs = {
        fzf = {
          enable = true;
          enableFishIntegration = false;
        };

        eza = {
          enable = true;
          enableFishIntegration = true;
        };

        zoxide = {
          enable = true;
          enableFishIntegration = false;
          enableZshIntegration = false;
          enableNushellIntegration = true;
        };

        broot = {
          enable = true;
          enableFishIntegration = false;
          enableNushellIntegration = true;
        };

        devenv = {
          enable = true;
          enableFishIntegration = false;
          enableZshIntegration = false;
        };

        direnv = {
          enable = true;
          enableFishIntegration = false;
          enableZshIntegration = false;
          nix-direnv.enable = true;
        };

        carapace = {
          enable = true;
          enableFishIntegration = false;
          enableNushellIntegration = true;
        };

        atuin = {
          enable = true;
          # Shell inits are generated at build time below.
          enableFishIntegration = false;
          enableZshIntegration = false;
          enableNushellIntegration = true;
        };

        pay-respects = {
          enable = true;
          enableFishIntegration = false;
          enableNushellIntegration = true;
        };

        bat = {
          enable = true;
          config = {
            theme = "Catppuccin Mocha";
          };
          extraPackages = with pkgs.bat-extras; [
            batgrep
            batman
            batpipe
            batwatch
            batdiff
            prettybat
          ];
        };

        btop = {
          enable = true;
          package = pkgs.btop.override {
            cudaSupport = true;
          };
          settings = {
            color_theme = "Dracula";
            theme_background = false;
            vim_keys = true;
          };
        };

        fish.interactiveShellInit = lib.mkIf config.programs.fish.enable (
          lib.mkAfter (
            lib.optionalString config.programs.zoxide.enable ''
              source ${zoxideFishInit}
            ''
            + lib.optionalString config.programs.devenv.enable ''
              source ${devenvFishHook}
            ''
            + lib.optionalString config.programs.atuin.enable ''
              # Create the session id here instead of letting the init script
              # spawn `atuin uuid` (same 32-hex format, version-7 nibble set).
              if not set -q ATUIN_SESSION; or test "$ATUIN_SHLVL" != "$SHLVL"
                  set -gx ATUIN_SESSION (printf '%04x%04x%04x7%03x%04x%04x%04x%04x' (random 0 65535) (random 0 65535) (random 0 65535) (random 0 4095) (random 32768 49151) (random 0 65535) (random 0 65535) (random 0 65535))
                  set -gx ATUIN_SHLVL $SHLVL
              end
              source ${atuinFishInit}
            ''
          )
        );

        # Runs after the conf.d sourcing (order 1000) and the compinit replay
        # (order 1010) in modules/shell/shells/zsh.nix, before starship.
        zsh.initContent = lib.mkIf config.programs.zsh.enable (
          lib.mkOrder 1020 (
            lib.optionalString config.programs.zoxide.enable ''
              source ${zoxideZshInit}
            ''
            + lib.optionalString config.programs.direnv.enable ''
              source ${direnvZshHook}
            ''
            + lib.optionalString config.programs.devenv.enable ''
              source ${devenvZshHook}
            ''
            + lib.optionalString config.programs.atuin.enable ''
              if [[ $options[zle] = on ]]; then
                # Create the session id here instead of letting the init script
                # spawn `atuin uuid` (same 32-hex format, version-7 nibble set).
                if [[ -z ''${ATUIN_SESSION:-} || ''${ATUIN_SHLVL:-} != $SHLVL ]]; then
                  printf -v ATUIN_SESSION '%04x%04x%04x7%03x%04x%04x%04x%04x' \
                    $(( RANDOM << 1 ^ RANDOM )) $(( RANDOM << 1 ^ RANDOM )) $(( RANDOM << 1 ^ RANDOM )) \
                    $(( RANDOM % 4096 )) $(( 32768 + RANDOM % 16384 )) \
                    $(( RANDOM << 1 ^ RANDOM )) $(( RANDOM << 1 ^ RANDOM )) $(( RANDOM << 1 ^ RANDOM ))
                  export ATUIN_SESSION ATUIN_SHLVL=$SHLVL
                fi
                source ${atuinZshInit}
              fi
            ''
          )
        );
      };
    };
}
