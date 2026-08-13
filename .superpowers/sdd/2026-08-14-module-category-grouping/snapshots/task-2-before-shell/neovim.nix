{ lib, ... }:
{
  den.aspects.shell._.neovim.homeManager =
    { pkgs, ... }:
    {
      xdg.configFile."nvim" = {
        source = ../../dots/config/nvim;
        recursive = true;
      };

      programs = {
        fish.interactiveShellInit = lib.mkAfter ''
          abbr --add nv nvim
        '';
        neovim = {
          enable = true;
          plugins = with pkgs.vimPlugins; [
            nvim-treesitter.withAllGrammars
          ];
        };
      };
    };
}
