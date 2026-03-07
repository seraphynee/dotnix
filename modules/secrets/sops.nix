{
  __findFile,
  inputs,
  constants,
  ...
}:
let
  # `sops-nix` activation runs as root; use absolute path, not `~`.
  # This file can contain AGE secret keys and/or AGE-PLUGIN-YUBIKEY identities.
  sharedSopsFile = ../../secrets/shared/secrets.yaml;
in
{
  den.aspects.secrets._.sops = {
    homeManager = {
      home.sessionVariables = {
        SOPS_AGE_KEY_FILE = "$HOME/.local/state/ages/keys.txt";
      };
    };

    provides = {
      esquire = {
        includes = [ <secrets/sops> ];

        homeManager =
          { config, ... }:
          {
            imports = [ inputs.sops-nix.homeManagerModules.sops ];

            sops = {
              defaultSopsFile = ../../secrets/esquire/secrets.yaml;
              validateSopsFiles = false;

              age = {
                keyFile = "${config.home.homeDirectory}/.local/state/ages/keys.txt";
                generateKey = false;
              };

              secrets = {
                "ssh/config" = { };
                "ssh/keys/signing/ghspy-pub" = { };
              };
            };

            programs.ssh = {
              extraConfig = ''
                # This file will be generated with sops and if sops fails to generate
                # it this directive will be skipped.
                Include ${config.sops.secrets."ssh/config".path}
              '';
            };
          };
        nixos =
          { pkgs, config, ... }:
          let
            userHome = config.users.users.${constants.user_two}.home or "/home/${constants.user_two}";
          in
          {
            imports = [ inputs.sops-nix.nixosModules.sops ];

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
              defaultSopsFile = ../../secrets/esquire/secrets.yaml;
              validateSopsFiles = false;

              age = {
                # automatically import host SSH keys as age keys
                sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
                # this will use an age key that is expected to already be in the filesystem
                keyFile = "/var/lib/sops-nix/keys.txt";
                # generate a new key if the key specified above does not exist
                generateKey = false;
              };

              gnupg = {
                sshKeyPaths = [ ];
              };

              # secrets will be output to /run/secrets
              # e.g. /run/secrets/<secret-name>
              secrets = {
                "ssh/keys/auth/ghspy-pub" = {
                  name = "ghspy-pub";
                  path = "${userHome}/.ssh_keys/ghspy-auth.pub";
                  owner = "${constants.user_two}";
                  mode = "0600";
                };
                "ssh/keys/signing/ghspy-pub" = {
                  name = "ghspy-pub";
                  path = "${userHome}/.ssh_keys/ghspy-signing.pub";
                  owner = "${constants.user_two}";
                  mode = "0600";
                };
                "password/seraphyne" = {
                  neededForUsers = true;
                };
              };
            };
          };
      };

      acerus = {
        includes = [ <secrets/sops> ];

        nixos =
          { pkgs, ... }:
          {
            imports = [ inputs.sops-nix.nixosModules.sops ];

            environment.systemPackages = with pkgs; [
              sops
              age
              age-plugin-yubikey
              yubikey-manager
              yubico-piv-tool
              pcsclite
            ];
            services.pcscd.enable = true;

            sops = {
              defaultSopsFile = ../../secrets/acerus/secrets.yaml;
              validateSopsFiles = false;

              age = {
                sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
                keyFile = "/var/lib/sops-nix/keys.txt";
                generateKey = false;
              };

              gnupg = {
                sshKeyPaths = [ ];
              };

              secrets = {
                "password/seraphyne" = {
                  neededForUsers = true;
                };
              };
            };
          };
      };

      mbp = {
        includes = [ <secrets/sops> ];

        homeManager =
          { config, ... }:
          {
            imports = [ inputs.sops-nix.homeManagerModules.sops ];

            sops = {
              defaultSopsFile = ../../secrets/mbp/secrets.yaml;
              validateSopsFiles = false;

              age = {
                keyFile = "${config.home.homeDirectory}/.local/state/ages/keys.txt";
                generateKey = false;
              };

              secrets = {
                "ssh/keys/signing/ghcny-pub" = { };
              };
            };
          };

        darwin =
          { pkgs, config, ... }:
          let
            userHome = config.users.users.${constants.user_one}.home or "/Users/${constants.user_one}";
          in
          {
            imports = [ inputs.sops-nix.darwinModules.sops ];

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
              defaultSopsFile = ../../secrets/mbp/secrets.yaml;
              validateSopsFiles = false;

              age = {
                # automatically import host SSH keys as age keys
                # sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
                # this will use an age key that is expected to already be in the filesystem
                keyFile = "${userHome}/.local/state/ages/keys.txt";
                # generate a new key if the key specified above does not exist
                generateKey = true;
              };

              gnupg = {
                sshKeyPaths = [ ];
              };

              # secrets will be output to /run/secrets by default
              # e.g. /run/secrets/<secret-name>
              secrets = {
                "keys/ssh/auth/ghspy-pub" = {
                  name = "ghspy-pub";
                  sopsFile = sharedSopsFile;
                  path = "${userHome}/.ssh_keys/ghspy.pub";
                  owner = "${constants.user_one}";
                  mode = "0600";
                };

                "passwords/chianyung" = {
                  sopsFile = sharedSopsFile;
                  neededForUsers = true;
                };
              };
            };
          };
      };
    };
  };
}
