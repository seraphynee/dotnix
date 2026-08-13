{ lib, ... }:
{
  den.aspects.shell._.lazygit.homeManager = {
    programs.fish.interactiveShellInit = lib.mkAfter ''
      abbr --add lzg lazygit
    '';
    programs.lazygit = {
      enable = true;
      enableFishIntegration = false;
      settings = {
        git = {
          diffRenderers = [
            {
              type = "extDiff";
              command = "difft --color=always";
            }
          ];
        };
      };
    };
  };
}
