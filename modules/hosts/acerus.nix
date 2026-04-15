{
  __findFile,
  constants,
  ...
}:
let
  mkAcerusAspect = bootloader: {
    nixos =
      { lib, pkgs, ... }:
      {
        imports = [ ];

        boot.initrd.availableKernelModules = [
          "vmd"
          "nvme"
          "ahci"
          "xhci_pci"
          "usbhid"
          "usb_storage"
          "sd_mod"
          "sr_mod"
        ];

        # Acer Swift Go SFG14-73 is a modern Intel laptop, so prefer a newer
        # kernel plus the usual firmware/microcode baseline.
        boot.kernelPackages = pkgs.linuxPackages_latest;

        hardware.cpu.intel.updateMicrocode = true;
        hardware.enableRedistributableFirmware = true;

        # services.fwupd.enable = true;
        services.hardware.bolt.enable = true;
      };

    includes = [
      <disko/btrfs-luks>
      bootloader
      <system/impermanence>

      <system/locale>
      <system/ssh>
      <system/sshd>
      <system/audio>
      <system/bluetooth>
      <system/fonts>
      <system/networking>
      <system/xdg>
      <system/settings>

      <desktop/wm/mango>
      <desktop/qs/noctalia>

      <apps/discord>
      <apps/firefox>
      <apps/ghostty>
      <apps/helium>
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
