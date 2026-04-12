{
  den.aspects.system._.networking = {
    nixos = {
      networking = {
        networkmanager.enable = true;
        nameservers = [
          "1.1.1.1" # Cloudflare
          "8.8.8.8" # Google
        ];
      };
    };
  };
}
