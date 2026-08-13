{ lib, ... }:
{
  den.aspects.system._.audio.nixos =
    { pkgs, ... }:
    {
      services.pipewire = {
        enable = true;
        audio.enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };

      services.pulseaudio.enable = false;

      environment.systemPackages = with pkgs; [
        pavucontrol # PulseAudio volume control
        playerctl # Media player control
        pulseaudio # For pactl command
      ];
    };

  den.aspects.system._.bluetooth.nixos =
    { pkgs, ... }:
    {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
      services.blueman.enable = true;

      environment.systemPackages = with pkgs; [
        bluetui
        bluetuith
      ];
    };

  den.aspects.system._.nvidia.nixos =
    { lib, ... }:
    {
      nixpkgs.config.allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "nvidia-x11"
        ];

      services.xserver.videoDrivers = [ "nvidia" ];
      hardware = {
        graphics = {
          enable = true;
          enable32Bit = true;
        };
        nvidia = {
          open = true;
          nvidiaSettings = true;
          modesetting.enable = true;
          powerManagement.enable = true;
          powerManagement.finegrained = false;
        };
      };
    };

  den.aspects.system._.tpm.nixos = {
    boot.initrd = {
      systemd = {
        enable = true;
        tpm2.enable = true;
      };

      luks.devices.crypted.crypttabExtraOpts = [ "tpm2-device=auto" ];
    };

    security.tpm2.enable = true;
  };
}
