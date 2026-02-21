{
  __findFile,
  inputs,
  ...
}: let
  # `sops-nix` activation runs as root; use absolute path, not `~`.
  # This file can contain AGE secret keys and/or AGE-PLUGIN-YUBIKEY identities.
  ageKeyFile = "/var/sops/age/keys.txt";
in {
  den.aspects.secrets._.sops = {
    nixos = {pkgs, ...}: {
      imports = [inputs.sops-nix.nixosModules.sops];

      environment.systemPackages = with pkgs; [
        sops
        age
        age-plugin-yubikey
        yubikey-manager # optional but handy (ykman)
        yubico-piv-tool # optional but handy (PIV debugging)
        pcsclite
      ];
      services.pcscd.enable = true;

      sops = {
        # `secrets.yaml` is encrypted for AGE recipient from YubiKey.
        defaultSopsFile = ../../secrets/secrets.yaml;
        age = {
          # keyFile = ageKeyFile;
          # Prevent fallback to host SSH keys like `/etc/ssh/ssh_host_rsa_key`.
          sshKeyPaths = [];
        };
      };
    };

    darwin = {pkgs, ...}: {
      imports = [inputs.sops-nix.darwinModules.sops];

      environment.systemPackages = with pkgs; [
        sops
        age
        age-plugin-yubikey
        yubikey-manager # optional but handy (ykman)
        yubico-piv-tool # optional but handy (PIV debugging)
        pcsclite
        ssh-to-age
      ];

      programs.ssh.extraConfig = ''
        Host spy
          User git
          Hostname github.com
          IdentityFile /run/secrets/git-seraphyne
          IdentitiesOnly yes
      '';

      sops = {
        # `secrets.yaml` is encrypted for AGE recipient from YubiKey.
        defaultSopsFile = ../../secrets/secrets.yaml;
        age = {
          keyFile = ageKeyFile;
          # Prevent fallback to host SSH keys like `/etc/ssh/ssh_host_rsa_key`.
          sshKeyPaths = [];
        };

        secrets.git-seraphyne = {
          owner = "chianyung";
          mode = "0400";
        };
        #     secrets.seraphyne = {
        #       # Key name inside secrets.yaml (typo kept for backward compatibility).
        #       key = "serapyhne";
        #
        #       # path file hasil decrypt:
        #       path = "/run/secrets/seraphyne";
        #       mode = "0400";
        #
        #       # kalau key ini dipakai oleh user tertentu:
        #       owner = "chianyung"; # ganti usermu
        #     };
        #   };
        #
      };
    };
  };
}
