_:
{
  den.aspects.shell._.my-scripts.homeManager =
    { pkgs, ... }:
    let
      testspeed = pkgs.writeShellApplication {
        name = "testspeed";
        runtimeInputs = [
          pkgs.gum
          pkgs.ookla-speedtest
        ];
        text = builtins.readFile ../../scripts/testspeed.sh;
      };
    in
    {
      home.packages = [ testspeed ];
    };
}
