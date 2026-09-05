{ paths, ... }:
{
  den.aspects.shell._.my-scripts.homeManager =
    { pkgs, ... }:
    let
      jjTaskClone = pkgs.writeShellApplication {
        name = "jj-task-clone";
        runtimeInputs = with pkgs; [
          jujutsu
          gum
        ];
        text = builtins.readFile (paths.scripts + "/jj-task-clone.sh");
      };

      testspeed = pkgs.writeShellApplication {
        name = "testspeed";
        runtimeInputs = [
          pkgs.gum
          pkgs.ookla-speedtest
        ];
        text = builtins.readFile (paths.scripts + "/testspeed.sh");
      };
    in
    {
      home.packages = [
        jjTaskClone
        testspeed
      ];
    };
}
