{
  den.aspects.system._.fingerprint.nixos =
    { config, ... }:
    {
      services.fprintd.enable = true;

      environment.systemPackages = [
        config.services.fprintd.package
      ];

      # Keep the enabled PAM services explicit so fingerprint usage is predictable
      # on this host instead of relying on implicit defaults.
      security.pam.services = {
        login.fprintAuth = true;
        sudo.fprintAuth = true;
        polkit-1.fprintAuth = true;
        sddm.fprintAuth = true;
        swaylock.fprintAuth = true;
      };
    };
}
