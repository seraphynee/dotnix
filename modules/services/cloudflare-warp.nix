{
  den.aspects.services._."cloudflare-warp".nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.cloudflare-warp
      ];

      services.cloudflare-warp = {
        enable = true;
        package = pkgs.cloudflare-warp;
      };
    };
}
