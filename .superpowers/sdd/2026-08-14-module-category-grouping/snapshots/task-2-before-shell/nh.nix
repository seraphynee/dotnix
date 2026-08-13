{
  den.aspects.shell._.nh.homeManager =
    {
      config,
      pkgs,
      ...
    }:
    {
      home.packages = with pkgs; [
        # Workflow-specific companions for nh.
        nh
        nix-output-monitor
        nix-fast-build
        nvd
        nix-diff
      ];

      programs.nh = {
        enable = true;
        osFlake = "${config.home.homeDirectory}/dotnix";
      };
    };
}
