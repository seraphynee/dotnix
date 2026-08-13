{
  # Cloudflare WARP
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

  # Tailscale
  den.aspects.services._.tailscale.nixos =
    {
      pkgs,
      config,
      ...
    }:
    {
      environment.systemPackages = [
        pkgs.tailscale
      ];

      services.tailscale = {
        enable = true;
        package = pkgs.tailscale;
        useRoutingFeatures = "both";
      };

      networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];
      # Allow Tailscale traffic
      networking.firewall.trustedInterfaces = [ "tailscale0" ];
    };
}
