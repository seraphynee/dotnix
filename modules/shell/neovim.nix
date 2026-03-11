{ lib, ... }:
{
  den.aspects.shell._.neovim.homeManager =
    { pkgs, ... }:
    {
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
        xdg.configFile."nvim" = {
          source = ../../dots/config/nvim;
          recursive = true;
        };
      };
    };
}
