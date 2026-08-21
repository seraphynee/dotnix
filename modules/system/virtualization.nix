{ constants, ... }:
{
  den.aspects.system._.podman.nixos = {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      autoPrune.enable = true;
    };
    virtualisation.oci-containers.backend = "podman";
  };

  den.aspects.system._.virt.nixos =
    {
      lib,
      options,
      pkgs,
      ...
    }:
    lib.mkMerge [
      {
        users.users.${constants.user.seraphynee.username}.extraGroups = [
          "libvirtd"
          "kvm"
        ];

        boot.kernelModules = [ "kvm-intel" ];

        environment.systemPackages = with pkgs; [
          qemu_kvm
          quickemu
          quickgui
          virt-manager
          virt-viewer
          spice
          spice-gtk
          spice-protocol
          virtio-win
          win-spice
        ];

        virtualisation = {
          libvirtd = {
            enable = true;
            qemu = {
              package = pkgs.qemu_kvm;
              runAsRoot = true;
              swtpm.enable = true;
            };
          };
          spiceUSBRedirection.enable = true;
        };
        services.spice-vdagentd.enable = true;
      }
      (lib.optionalAttrs (options.environment ? persistence) {
        environment.persistence."/persist".directories = [ "/var/lib/libvirt" ];
      })
    ];
}
