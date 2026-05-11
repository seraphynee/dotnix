{ __findFile, constants, ... }:
{
  den.hosts.x86_64-linux.vps.users = {
    ${constants.user_vps} = { };
  };

  den.aspects.vps = {
    includes = [
      <disko/simple>
      <system/bootloader/grub>
      <system/locale>
      <system/sshd>
      <secrets/sops/vps>
    ];
    nixos =
      { config, lib, ... }:
      {
        disko.devices.disk.basic.device = lib.mkDefault "/dev/sda";
        boot.loader.grub.devices = lib.mkDefault [ config.disko.devices.disk.basic.device ];

        networking = {
          useDHCP = lib.mkDefault true;
          firewall = {
            enable = true;
            allowedTCPPorts = [ 22 ];
          };
        };
      };
  };
}
