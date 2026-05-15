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

        # The internal touchpad on SFG14-73 variants is exposed as an ACPI
        # I2C-HID device behind Intel Serial IO. Load this stack early so the
        # touchpad is consistently present for libinput/Wayland.
        boot.initrd.kernelModules = [
          "intel_lpss"
          "intel_lpss_pci"
          "i2c_designware_pci"
          "i2c_hid_acpi"
          "hid_multitouch"
        ];

        hardware.cpu.intel.updateMicrocode = true;
        hardware.enableRedistributableFirmware = true;

        # services.fwupd.enable = true;
        services.hardware.bolt.enable = true;

        services.pipewire.wireplumber = {
          enable = true;
          extraConfig."51-acerus-internal-speakers" = {
            "device.profile.priority.rules" = [
              {
                matches = [
                  {
                    "device.name" = "alsa_card.pci-0000_00_1f.3-platform-skl_hda_dsp_generic";
                  }
                ];
                actions.update-props.priorities = [
                  "HiFi (HDMI1, HDMI2, HDMI3, Mic1, Mic2, Speaker)"
                  "HiFi (HDMI1, HDMI2, HDMI3, Headphones, Mic1, Mic2)"
                ];
              }
            ];
          };
        };
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

      <apps/chromium>
      <apps/discord>
      <apps/firefox>
      <apps/ghostty>
      <apps/wezterm>
      <apps/zen>
      <apps/zed>

      <services/cloudflare-warp>
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
