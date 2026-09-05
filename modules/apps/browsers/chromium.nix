_: {
  den.aspects.apps._.chromium = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [
          pkgs.brave
        ];
      };
  };
}
