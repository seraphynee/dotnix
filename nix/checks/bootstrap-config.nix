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
    };
}
