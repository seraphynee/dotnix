{ lib, ... }:
{
  # Helix
  den.aspects.shell._.helix = {
    homeManager = {
      xdg.configFile."helix" = {
        source = ../../dots/config/helix;
        recursive = true;
      };
    };

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ helix ];
      };
    darwin =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ helix ];
      };
  };
  # Nano
  den.aspects.shell._.nano.homeManager =
    { config, pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
      nanorc = builtins.replaceStrings [ "@XDG_DATA_HOME@" ] [ config.xdg.dataHome ] (
        builtins.readFile ../../dots/config/nano/nanorc
      );
    in
    lib.mkIf (isDarwin || isLinux) {
      home.packages = [ pkgs.nano ];

      xdg.configFile."nano/nanorc".text = nanorc;
    };
  # Neovim
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
