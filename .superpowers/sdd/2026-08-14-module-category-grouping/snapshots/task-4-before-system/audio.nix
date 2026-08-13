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
}
