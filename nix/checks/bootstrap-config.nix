{
  constants,
  lib,
  self,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    let
      acerusConfig = self.nixosConfigurations.acerus.config;
      acerusInstallerConfig = self.nixosConfigurations.acerus-installer.config;
      groupsFor = config: config.users.users.seraphynee.extraGroups;
      persistentDirectoriesFor =
        config: map (directory: directory.directory) config.environment.persistence."/persist".directories;
      diskFor = host: self.nixosConfigurations.${host}.config.disko.devices.disk.btrfs.device;
      acerusDisk = diskFor "acerus-installer";
      esquireDisk = diskFor "esquire-installer";
    in
    {
      checks.bootstrap-disk-config =
        assert acerusDisk == "/dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b47e55428";
        assert esquireDisk == constants.hosts.esquire.systemDisk;
        assert lib.hasPrefix "/dev/disk/by-id/" acerusDisk;
        assert lib.hasPrefix "/dev/disk/by-id/" esquireDisk;
        pkgs.runCommand "bootstrap-disk-config" { } ''
          touch "$out"
        '';

      checks.acerus-virtualization-enabled =
        assert acerusConfig.virtualisation.libvirtd.enable;
        assert acerusInstallerConfig.virtualisation.libvirtd.enable;
        assert lib.elem "libvirtd" (groupsFor acerusConfig);
        assert lib.elem "kvm" (groupsFor acerusConfig);
        assert lib.elem "libvirtd" (groupsFor acerusInstallerConfig);
        assert lib.elem "kvm" (groupsFor acerusInstallerConfig);
        pkgs.runCommand "acerus-virtualization-enabled" { } ''
          touch "$out"
        '';

      checks.acerus-libvirt-persistence =
        assert lib.elem "/var/lib/libvirt" (persistentDirectoriesFor acerusConfig);
        assert lib.elem "/var/lib/libvirt" (persistentDirectoriesFor acerusInstallerConfig);
        pkgs.runCommand "acerus-libvirt-persistence" { } ''
          touch "$out"
        '';
    };
}
