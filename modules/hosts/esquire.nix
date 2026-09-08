{
  __findFile,
  constants,
  ...
}:
let
  mkEsquireAspect = bootloader: {
    nixos =
      { lib, ... }:
      {
        imports = [ ];

        boot.initrd.availableKernelModules = [
          "nvme"
          "ahci"
          "xhci_pci"
          "usbhid"
          "usb_storage"
          "sd_mod"
          "sr_mod"
        ];

        disko.devices.disk.btrfs.device = lib.mkForce constants.hosts.esquire.systemDisk;
      };

    includes = [
      <disko/btrfs-luks>
      bootloader
      <system/impermanence>

      <profile/workstation>

      <system/nvidia>
      <system/podman>
      <apps/datagrip>
      <apps/vscode>

      <secrets/sops/esquire>
    ];
  };
in
{
  den.hosts.x86_64-linux.esquire.users = {
    ${constants.user.seraphynee.username} = { };
  };

  den.hosts.x86_64-linux."esquire-installer".users = {
    ${constants.user.seraphynee.username} = { };
  };

  den.aspects.esquire = mkEsquireAspect <system/bootloader/lanzaboote>;
  den.aspects."esquire-installer" = mkEsquireAspect <system/bootloader/systemd-boot>;
}
