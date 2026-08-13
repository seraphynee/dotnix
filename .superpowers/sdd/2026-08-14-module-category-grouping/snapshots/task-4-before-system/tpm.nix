{
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
