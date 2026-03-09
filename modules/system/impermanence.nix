{ inputs, ... }:
{
  den.aspects.system._.impermanence.nixos =
    { pkgs, ... }:
    {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      fileSystems."/persist".neededForBoot = true;

      environment.persistence."/persist" = {
        enable = true;
        hideMounts = true;
        files = [
          "/etc/machine-id"
          "/var/lib/systemd/random-seed"
        ];
        directories = [
          "/etc/secureboot"
          "/etc/ssh"
          "/var/lib/NetworkManager"
          "/etc/NetworkManager/system-connections"
          "/var/lib/nixos"
          "/var/lib/systemd/coredump"
          "/var/lib/tpm2-tss"
          "/var/lib/tailscale"
          "/var/lib/sops-nix"
          "/var/lib/bluetooth"
          "/var/log"
        ];
      };

      boot.initrd.systemd = {
        extraBin.btrfs = "${pkgs.btrfs-progs}/bin/btrfs";

        services.rollback-root = {
          description = "Rollback root subvolume";
          wantedBy = [ "sysroot.mount" ];
          before = [ "sysroot.mount" ];
          wants = [ "systemd-cryptsetup@crypted.service" ];
          after = [ "systemd-cryptsetup@crypted.service" ];
          unitConfig.DefaultDependencies = "no";
          serviceConfig.Type = "oneshot";
          script = ''
            mkdir -p /btrfs
            mount -t btrfs -o subvolid=5 /dev/mapper/crypted /btrfs

            if [ ! -e /btrfs/@blank ]; then
              btrfs subvolume snapshot /btrfs/@ /btrfs/@blank
            fi

            if [ -e /btrfs/@ ]; then
              btrfs subvolume delete /btrfs/@
            fi

            btrfs subvolume snapshot /btrfs/@blank /btrfs/@
            umount /btrfs
          '';
        };
      };
    };
}
