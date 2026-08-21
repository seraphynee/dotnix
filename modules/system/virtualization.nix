{ constants, ... }:
{
  den.aspects.system._.podman.nixos = {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      autoPrune.enable = true;
    };
    virtualisation.oci-containers.backend = "podman";
  };

  den.aspects.system._.virt.nixos =
    { lib, options, ... }:
    lib.mkMerge [
      {
        users.users.${constants.user.seraphynee.username}.extraGroups = [ "incus-admin" ];

        networking = {
          nftables.enable = true;
          firewall.interfaces.incusbr0 = {
            allowedTCPPorts = [ 53 ];
            allowedUDPPorts = [
              53
              67
            ];
          };
        };

        virtualisation.incus = {
          enable = true;
          preseed = {
            networks = [
              {
                name = "incusbr0";
                type = "bridge";
                config = {
                  "ipv4.address" = "auto";
                  "ipv4.nat" = "true";
                  "ipv6.address" = "none";
                };
              }
            ];
            profiles = [
              {
                name = "default";
                devices = {
                  eth0 = {
                    name = "eth0";
                    network = "incusbr0";
                    type = "nic";
                  };
                  root = {
                    path = "/";
                    pool = "default";
                    type = "disk";
                  };
                };
              }
            ];
            storage_pools = [
              {
                name = "default";
                driver = "dir";
                config.source = "/var/lib/incus/storage-pools/default";
              }
            ];
          };
        };
      }
      (lib.optionalAttrs (options.environment ? persistence) {
        environment.persistence."/persist".directories = [ "/var/lib/incus" ];
      })
    ];
}
