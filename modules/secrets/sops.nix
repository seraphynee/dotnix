{
  __findFile,
  inputs,
  ...
}: let
  # `sops-nix` activation runs as root; use absolute path, not `~`.
  # This file can contain AGE secret keys and/or AGE-PLUGIN-YUBIKEY identities.
  ageKeyFile = "/Users/chianyung/.config/sops/age/keys.txt";
  sharedSopsFile = ../../secrets/shared/secrets.yaml;
  mbpSopsFile = ../../secrets/mbp/secrets.yaml;
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
        # Shared secrets are read from `common` by default.
        # Host-specific secrets should override `sopsFile` per secret.
        defaultSopsFile = sharedSopsFile;
        validateSopsFiles = false;

        age = {
          # automatically import host SSH keys as age keys
          sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
          # this will use an age key that is expected to already be in the filesystem
          keyFile = ageKeyFile;
          # generate a new key if the key specified above does not exist
          generateKey = true;
        };

        gnupg = {
          sshKeyPaths = [];
        };

        # secrets will be output to /run/secrets
        # e.g. /run/secrets/<secret-name>
        secrets = {
          "keys/ssh/gh-spy" = {};
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

      sops = {
        # Shared secrets are read from `common` by default.
        # Host-specific secrets should override `sopsFile` per secret.
        defaultSopsFile = sharedSopsFile;
        validateSopsFiles = false;

        age = {
          # automatically import host SSH keys as age keys
          sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
          # this will use an age key that is expected to already be in the filesystem
          keyFile = ageKeyFile;
          # generate a new key if the key specified above does not exist
          generateKey = true;
        };

        gnupg = {
          sshKeyPaths = [];
        };

        # secrets will be output to /run/secrets
        # e.g. /run/secrets/<secret-name>
        secrets = {
          "keys/ssh/gh-spy" = {};
          test = {
            sopsFile = ../../secrets/mbp/secrets.yaml;
          };
        };
      };
    };
  };
}
