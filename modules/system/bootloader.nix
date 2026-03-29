{ __findFile, inputs, ... }:
{
  den.aspects.system._.bootloader = {
    provides = {
      systemd-boot.nixos = {
        boot = {
          loader = {
            systemd-boot = {
              enable = true; # Enable systemd-boot as the bootloader.
              # configurationLimit = 10; # Keep the latest 10 boot entries.
              editor = false; # Disable editing kernel parameters at boot.
            };
            efi.canTouchEfiVariables = true; # Allow updating EFI NVRAM boot entries.
            timeout = 3; # Show the boot menu for 3 seconds.
          };
        };
      };

      lanzaboote = {
        includes = [ <system/tpm> ];

        nixos =
          {
            lib,
            pkgs,
            ...
          }:
          {
            imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

            environment.systemPackages = [ pkgs.sbctl ];

            boot.loader.systemd-boot = {
              enable = lib.mkForce false; # Let Lanzaboote manage systemd-boot to avoid conflicts.
              # configurationLimit = 10; # Keep the latest 10 boot entries.
              editor = false; # Disable editing kernel parameters at boot.

            };
            boot.lanzaboote = {
              enable = true;
              pkiBundle = "/etc/secureboot";

              autoGenerateKeys.enable = true;
              autoEnrollKeys = {
                enable = true;
                autoReboot = true;
              };
            };
          };
      };
    };
  };
}
