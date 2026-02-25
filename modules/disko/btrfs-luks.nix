{lib, ...}: let
  device = lib.mkDefault "/dev/disk/by-id/nvme-eui.002538ba11b6cb55";
  luksName = "crypted";
  swapSizeMiB = 8192;
  mountOptions = [
    "noatime"
    "compress=zstd"
  ];
  swapMountOptions = [
    "noatime"
    "nodatacow"
  ];
in {
  den.aspects.disko._."btrfs-luks".nixos = {
    services.fstrim.enable = true;
    swapDevices = [
      {
        device = "/.swapvol/swapfile";
        size = swapSizeMiB;
      }
    ];

    disko = {
      devices = {
        disk = {
          btrfs = {
            type = "disk";
            inherit device;
            content = {
              type = "gpt";
              partitions = {
                ESP = {
                  priority = 1;
                  name = "ESP";
                  start = "1M";
                  end = "1G";
                  type = "EF00";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                    mountOptions = ["umask=0077"];
                  };
                };
                root = {
                  size = "100%";
                  content = {
                    type = "luks";
                    name = luksName;
                    settings = {
                      allowDiscards = true;
                    };
                    content = {
                      type = "btrfs";
                      extraArgs = ["-f"];
                      subvolumes = {
                        "@" = {
                          mountpoint = "/";
                          inherit mountOptions;
                        };
                        "@home" = {
                          mountpoint = "/home";
                          inherit mountOptions;
                        };
                        "@nix" = {
                          mountpoint = "/nix";
                          inherit mountOptions;
                        };
                        "@persist" = {
                          mountpoint = "/persist";
                          inherit mountOptions;
                        };
                        "@swap" = {
                          mountpoint = "/.swapvol";
                          mountOptions = swapMountOptions;
                        };
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
