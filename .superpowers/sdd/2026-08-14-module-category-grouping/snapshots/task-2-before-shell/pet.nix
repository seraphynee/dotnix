{
  den.aspects.shell._.pet.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.pet ];
      xdg.configFile."pet" = {
        source = ../../dots/config/pet;
        recursive = true;
      };
    };
}
