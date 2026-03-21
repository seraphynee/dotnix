{
  __findFile,
  constants,
  ...
}:
let
  mkAcerusAspect = bootloader: {
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
      <system/xdg>
      <system/settings>

      <desktop/wm/mango>
      <desktop/qs/noctalia>

      <apps/discord>
      <apps/firefox>
      <apps/ghostty>
      <apps/wezterm>
      <apps/zen>
      <apps/zed>

      <services/tailscale>
      <services/kanata>

      <secrets/sops/acerus>
    ];
  };
in
{
  den.hosts.x86_64-linux.acerus.users = {
    ${constants.user_two} = { };
  };

  den.hosts.x86_64-linux."acerus-installer".users = {
    ${constants.user_two} = { };
  };

  den.aspects.acerus = mkAcerusAspect <system/bootloader/lanzaboote>;
  den.aspects."acerus-installer" = mkAcerusAspect <system/bootloader/systemd-boot>;
}
