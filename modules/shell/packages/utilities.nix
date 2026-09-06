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
        };

        direnv = {
          enable = true;
          enableFishIntegration = false;
          nix-direnv.enable = true;
        };

        carapace = {
          enable = true;
          enableFishIntegration = false;
          enableNushellIntegration = true;
        };

        atuin = {
          enable = true;
          enableFishIntegration = true;
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
          )
        );
      };
    };
}
