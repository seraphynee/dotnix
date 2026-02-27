{
  __findFile,
  constants,
  ...
}:
{
  den.hosts.x86_64-linux.esquire.users = {
    ${constants.user_two} = { };
  };

  den.aspects.esquire = {
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

      <system/systemd-boot>
      <system/locale>
      <system/ssh>
      <system/sshd>
      <system/audio>
      <system/fonts>
      <system/networking>
      <system/nvidia>
      <system/xdg>
      <system/settings>

      # <desktop/kde>
      # <desktop/gnome>
      <desktop/sddm>
      <desktop/niri>
      <desktop/dms>
      # <desktop/noctalia>

      <apps/ghostty>
      <apps/zen>
      <apps/firefox>

      <services/tailscale>
      <services/kanata>

      <secrets/sops/esquire>
    ];
  };
}
