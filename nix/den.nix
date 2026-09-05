{
  inputs,
  den,
  ...
}:
{
  _module.args.__findFile = den.lib.__findFile;

  _module.args.paths = {
    root = ../.;
    dots = ../dots;
    scripts = ../scripts;
    secrets = ../secrets;
  };

  systems = builtins.attrNames den.hosts;
  imports = [ inputs.den.flakeModule ];
}
