{ __findFile, inputs, ... }:
{
  den.aspects.shell._.worktrunk = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          inputs.worktrunk.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
      };
  };
}
