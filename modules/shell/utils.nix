{
  den.aspects.shell._.utils.homeManager =
    { pkgs, ... }:
    {
      services.ssh-agent = {
        enable = true;
        enableFishIntegration = false;
        enableNushellIntegration = true;
      };

      programs = {
        fzf = {
          enable = true;
          enableFishIntegration = false;
        };

        eza = {
          enable = true;
          enableFishIntegration = false;
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

        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };

        carapace = {
          enable = true;
          enableFishIntegration = false;
          enableNushellIntegration = true;
        };

        atuin = {
          enable = true;
          enableFishIntegration = false;
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
      };
    };
}
