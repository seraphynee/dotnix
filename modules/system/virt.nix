{ constants, ... }:
{
  den.aspects.system._.virt.nixos =
    { pkgs, ... }:
    {
      users.users.${constants.user_two}.extraGroups = [
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
    };
}
