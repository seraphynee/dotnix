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

      checks.acerus-incus-enabled =
        assert acerusConfig.virtualisation.incus.enable;
        assert acerusInstallerConfig.virtualisation.incus.enable;
        assert acerusConfig.networking.nftables.enable;
        assert acerusInstallerConfig.networking.nftables.enable;
        assert lib.elem "incus-admin" (groupsFor acerusConfig);
        assert lib.elem "incus-admin" (groupsFor acerusInstallerConfig);
        pkgs.runCommand "acerus-incus-enabled" { } ''
          touch "$out"
        '';

      checks.acerus-incus-persistence =
        assert lib.elem "/var/lib/incus" (persistentDirectoriesFor acerusConfig);
        assert lib.elem "/var/lib/incus" (persistentDirectoriesFor acerusInstallerConfig);
        pkgs.runCommand "acerus-incus-persistence" { } ''
          touch "$out"
        '';
    };
}
