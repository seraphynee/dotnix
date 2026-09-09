{ inputs, ... }:
{
  den.aspects.apps._.hister = {
    homeManager = {
      imports = [ inputs.hister.homeModules.default ];
      services.hister.enable = true;
    };
  };
}
