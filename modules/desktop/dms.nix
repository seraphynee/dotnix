{ __findFile, inputs, ... }:
{
  den.aspects.desktop._.dms.homeManager = {
    imports = [
      inputs.dms.homeModules.dank-material-shell
      inputs.dms.homeModules.niri
    ];

    programs.dank-material-shell = {
      enable = true;
      niri = {
        enableKeybinds = true; # Sets static preset keybinds
        enableSpawn = true; # Auto-start DMS with niri, if enabled
      };
    };
  };
}
