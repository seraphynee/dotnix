{
  __findFile,
  inputs,
  constants,
  lib,
  ...
}:
let
  inherit (lib) mkMerge optionalAttrs;

  # `sops-nix` activation runs as root; use absolute path, not `~`.
  # This file can contain AGE secret keys and/or AGE-PLUGIN-YUBIKEY identities.
  sharedSopsFile = ../../secrets/shared/secrets.yaml;

  hostSopsFiles = {
    esquire = ../../secrets/esquire/secrets.yaml;
    acerus = ../../secrets/acerus/secrets.yaml;
    mbp = ../../secrets/mbp/secrets.yaml;
  };

  sharedSopsPackages =
    pkgs: with pkgs; [
      sops
      age
      age-plugin-yubikey
      yubikey-manager
      yubico-piv-tool
      pcsclite
    ];

  mkSecretRef =
    {
      sopsFile ? null,
      key ? null,
      neededForUsers ? false,
    }:
    (optionalAttrs (sopsFile != null) { inherit sopsFile; })
    // (optionalAttrs (key != null) { inherit key; })
    // (optionalAttrs neededForUsers { inherit neededForUsers; });

  mkManagedFileSecret =
    {
      userHome,
      owner,
      fileName,
      sopsFile ? null,
      key ? null,
    }:
    (mkSecretRef { inherit sopsFile key; })
    // {
      name = fileName;
      path = "${userHome}/.ssh_keys/${fileName}";
      inherit owner;
      mode = "0600";
    };

  mkPasswordSecret =
    _:
    mkSecretRef {
      sopsFile = sharedSopsFile;
      neededForUsers = true;
    };

  mkHomeManagerSops =
    {
      extraSecrets ? { },
      sshIncludeSecret ? null,
    }:
    { config, ... }:
    mkMerge [
      {
        sops = {
          defaultSopsFile = sharedSopsFile;
          validateSopsFiles = false;

          age = {
            keyFile = "${config.home.homeDirectory}/.local/state/ages/keys.txt";
            generateKey = false;
          };

          secrets = {
            "espanso/email" = { };
            "llm/context7_apikey" = {
              key = "keys/api/context7";
            };
            "llm/openrouter_apikey" = {
              key = "keys/api/openrouter";
            };
            "llm/ref_apikey" = {
              key = "keys/api/ref";
            };
            "llm/tavily_apikey" = {
              key = "keys/api/tavily";
            };
          }
          // extraSecrets;
        };

        home.sessionVariables.SOPS_AGE_KEY_FILE = "$HOME/.local/state/ages/keys.txt";
      }
      (optionalAttrs (sshIncludeSecret != null) (
        let
          secretPath = config.sops.secrets.${sshIncludeSecret}.path;
        in
        {
          programs.ssh.extraConfig = ''
            # This file will be generated with sops and if sops fails to generate
            # it this directive will be skipped.
            Include ${secretPath}
          '';
        }
      ))
    ];

  mkNixosSops =
    {
      userName,
      extraSecrets ? (_: { }),
    }:
    { pkgs, config, ... }:
    let
      userHome = config.users.users.${userName}.home or "/home/${userName}";
    in
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];
      home-manager.sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];

      environment.systemPackages = sharedSopsPackages pkgs;
      services.pcscd.enable = true;

      sops = {
        defaultSopsFile = sharedSopsFile;
        validateSopsFiles = false;

        age = {
          sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
          keyFile = "/var/lib/sops-nix/keys.txt";
          generateKey = false;
        };

        gnupg.sshKeyPaths = [ ];
        secrets = extraSecrets userHome;
      };
    };

  mkDarwinSops =
    {
      userName,
      extraSecrets ? (_: { }),
      generateKey ? true,
    }:
    { pkgs, config, ... }:
    let
      userHome = config.users.users.${userName}.home or "/Users/${userName}";
    in
    {
      imports = [ inputs.sops-nix.darwinModules.sops ];
      home-manager.sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];

      environment.systemPackages = (sharedSopsPackages pkgs) ++ [ pkgs.ssh-to-age ];

      sops = {
        defaultSopsFile = sharedSopsFile;
        validateSopsFiles = false;

        age = {
          keyFile = "${userHome}/.local/state/ages/keys.txt";
          inherit generateKey;
        };

        gnupg.sshKeyPaths = [ ];
        secrets = extraSecrets userHome;
      };
    };
in
{
  den.aspects.secrets._.sops = {
    provides = {
      esquire = {
        includes = [ <secrets/sops> ];

        homeManager = mkHomeManagerSops {
          sshIncludeSecret = "ssh/config";
          extraSecrets = {
            "ssh/config" = mkSecretRef {
              sopsFile = hostSopsFiles.esquire;
            };
            "keys/ssh/signing/ghspy-pub" = mkSecretRef {
              sopsFile = hostSopsFiles.esquire;
            };
            "keys/pat/ghspy-pat" = mkSecretRef {
              sopsFile = hostSopsFiles.esquire;
            };
          };
        };

        nixos = mkNixosSops {
          userName = constants.user_two;
          extraSecrets = userHome: {
            "keys/ssh/auth/ghspy-pub" = mkManagedFileSecret {
              inherit userHome;
              owner = constants.user_two;
              fileName = "ghspy.pub";
              sopsFile = hostSopsFiles.esquire;
            };
            "keys/ssh/signing/ghspy-pub" = mkManagedFileSecret {
              inherit userHome;
              owner = constants.user_two;
              fileName = "ghspy-signing.pub";
              sopsFile = hostSopsFiles.esquire;
            };
            "passwords/${constants.user_two}" = mkPasswordSecret constants.user_two;
          };
        };
      };

      acerus = {
        includes = [ <secrets/sops> ];

        nixos = mkNixosSops {
          userName = constants.user_two;
          extraSecrets = _: {
            "passwords/${constants.user_two}" = mkPasswordSecret constants.user_two;
          };
        };
      };

      mbp = {
        includes = [ <secrets/sops> ];

        homeManager = mkHomeManagerSops {
          extraSecrets = {
            "keys/ssh/signing/ghcny-pub" = mkSecretRef {
              sopsFile = hostSopsFiles.mbp;
              key = "ssh/keys/signing/ghcny-pub";
            };
          };
        };

        darwin = mkDarwinSops {
          userName = constants.user_one;
          extraSecrets = userHome: {
            "keys/ssh/auth/ghspy-pub" = mkManagedFileSecret {
              inherit userHome;
              owner = constants.user_one;
              fileName = "ghspy.pub";
              sopsFile = sharedSopsFile;
            };
            "passwords/${constants.user_one}" = mkPasswordSecret constants.user_one;
          };
        };
      };
    };
  };
}
