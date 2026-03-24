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

        disko.devices.disk.btrfs.device = lib.mkForce constants.mainDisk;
      };

    includes = [
      <disko/btrfs-luks>
      bootloader
      <system/impermanence>

      <system/locale>
      <system/ssh>
      <system/sshd>
      <system/audio>
      <system/fonts>
      <system/networking>
      <system/nvidia>
      <system/xdg>
      <system/settings>

      <desktop/wm/mango>
      <desktop/qs/noctalia>

      <apps/discord>
      <apps/datagrip>
      <apps/firefox>
      <apps/ghostty>
      <apps/vscode>
      <apps/wezterm>
      <apps/zed>
      <apps/zen>

      <services/tailscale>
      <services/kanata>

      <secrets/sops/esquire>
    ];
  };
in
{
  den.hosts.x86_64-linux.esquire.users = {
    ${constants.user_two} = { };
  };

  den.hosts.x86_64-linux."esquire-installer".users = {
    ${constants.user_two} = { };
  };

  den.aspects.esquire = mkEsquireAspect <system/bootloader/lanzaboote>;
  den.aspects."esquire-installer" = mkEsquireAspect <system/bootloader/systemd-boot>;
}
