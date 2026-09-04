{
  __findFile,
  inputs,
  ...
}:
{
  den.aspects.apps._.handy = {
    nixos =
      { pkgs, ... }:
      {
        imports = [ inputs.handy.nixosModules.default ];

        programs.handy.enable = true;

        # Handy uses wtype to paste transcriptions into Wayland applications.
        environment.systemPackages = [ pkgs.wtype ];
      };

    homeManager = {
      imports = [ inputs.handy.homeManagerModules.default ];
      services.handy.enable = true;
    };
  };
}
