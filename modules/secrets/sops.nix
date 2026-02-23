{
  __findFile,
  inputs,
  ...
}: let
  # `sops-nix` activation runs as root; use absolute path, not `~`.
  # This file can contain AGE secret keys and/or AGE-PLUGIN-YUBIKEY identities.
  ageKeyFile = "/var/sops/age/keys.txt";
  sopsFile = "../../secrets/secrets.yaml";
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
        defaultSopsFile = sopsFile;
        validateSopsFile = false;

        age = {
          keyFile = ageKeyFile;
          sshKeyPaths = [];
        };

        # secrets will be output to /run/secrets
        # e.g. /run/secrets/<secret-name>
        secrets = {
          example-key = {};
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
        defaultSopsFile = sopsFile;
        validateSopsFile = false;

        age = {
          keyFile = ageKeyFile;
          sshKeyPaths = [];
        };

        # secrets will be output to /run/secrets
        # e.g. /run/secrets/<secret-name>
        secrets = {
          example-key = {};
        };
      };
    };
  };
}
