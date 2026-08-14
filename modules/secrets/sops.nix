{
  lib,
  __findFile,
  inputs,
  constants,
  ...
}:
let
  inherit (lib) optionalAttrs recursiveUpdate;

  runtimeSecretNames = [
    "llm/context7_apikey"
    "llm/openrouter_apikey"
    "productivity/wakatime_apikey"
  ];

  runtimeSecretPath = config: name: "${config.xdg.configHome}/sops-nix/secrets/${name}";

  # `sops-nix` activation runs as root; use absolute path, not `~`.
  # This file can contain AGE secret keys and/or AGE-PLUGIN-YUBIKEY identities.
  sharedSopsFile = ../../secrets/shared/secrets.yaml;
  hostSopsFile = {
    esquire = ../../secrets/esquire/secrets.yaml;
    mbp = ../../secrets/mbp/secrets.yaml;
    acerus = ../../secrets/acerus/secrets.yaml;
    vps = ../../secrets/vps/secrets.yaml;
  };

  commonSopsPackages =
    pkgs: with pkgs; [
      sops
      age
      age-plugin-yubikey
      yubikey-manager
      yubico-piv-tool
      pcsclite
    ];

  systemPackagesOrEmpty =
    pkgs: extraPackages: if pkgs == null then [ ] else (commonSopsPackages pkgs) ++ extraPackages;

  mkSshInclude = config: {
    programs.ssh.extraConfig = ''
      # This file will be generated with sops and if sops fails to generate
      # it this directive will be skipped.
      Include ${config.sops.secrets."ssh/config".path}
    '';
  };

  mkHomeManagerSops =
    {
      defaultSopsFile ? null,
      secrets ? { },
      withSshInclude ? false,
      extraConfig ? { },
    }:
    { config, ... }:
    let
      runtimeSecrets = lib.mapAttrs (
        name: secret:
        if
          (builtins.elem name runtimeSecretNames || lib.hasPrefix "keys/pat/" name) && !(secret ? path)
        then
          secret // { path = runtimeSecretPath config name; }
        else
          secret
      ) secrets;
    in
    recursiveUpdate {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];

      sops = {
        validateSopsFiles = false;
        secrets = runtimeSecrets;

        age = {
          keyFile = "${config.home.homeDirectory}/.local/share/ages/keys.txt";
          generateKey = false;
        };
      }
      // optionalAttrs (defaultSopsFile != null) {
        inherit defaultSopsFile;
      };
    } (recursiveUpdate (optionalAttrs withSshInclude (mkSshInclude config)) extraConfig);

  mkNixosSops =
    {
      defaultSopsFile,
      secrets ? { },
      extraPackages ? [ ],
      extraConfig ? { },
      age ? {
        sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        keyFile = "/var/lib/sops-nix/keys.txt";
        generateKey = false;
      },
    }:
    {
      pkgs ? null,
      ...
    }:
    recursiveUpdate {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      environment.systemPackages = systemPackagesOrEmpty pkgs extraPackages;
      services.pcscd.enable = true;

      sops = {
        inherit defaultSopsFile secrets age;
        validateSopsFiles = false;

        gnupg = {
          sshKeyPaths = [ ];
        };
      };
    } extraConfig;

  mkDarwinSops =
    {
      defaultSopsFile,
      secrets ? { },
      extraPackages ? [ ],
      extraConfig ? { },
      age,
    }:
    {
      pkgs ? null,
      ...
    }:
    recursiveUpdate {
      imports = [ inputs.sops-nix.darwinModules.sops ];

      environment.systemPackages = systemPackagesOrEmpty pkgs extraPackages;

      sops = {
        inherit defaultSopsFile secrets age;
        validateSopsFiles = false;

        gnupg = {
          sshKeyPaths = [ ];
        };
      };
    } extraConfig;
in
{
  den.aspects.secrets._.sops = {
    homeManager = mkHomeManagerSops {
      defaultSopsFile = sharedSopsFile;
      secrets = {
        "espanso/email.yaml" = { };
        "llm/context7_apikey" = {
          key = "keys/api/context7";
        };
        "llm/openrouter_apikey" = {
          key = "keys/api/openrouter";
        };
        "productivity/wakatime_apikey" = {
          key = "keys/api/wakatime";
          mode = "0600";
        };
        "llm/ref_apikey" = {
          key = "keys/api/ref";
        };
        "llm/tavily_apikey" = {
          key = "keys/api/tavily";
        };
        "llm/oco_api_url" = {
          key = "keys/api/oco_url";
        };
        "llm/oco_api_key" = {
          key = "keys/api/oco_key";
        };
      };
      extraConfig.home.sessionVariables = {
        SOPS_AGE_KEY_FILE = "$HOME/.local/share/ages/keys.txt";
      };
    };

    provides = {
      vps = {
        includes = [ <secrets/sops> ];

        nixos = mkNixosSops {
          defaultSopsFile = hostSopsFile.vps;
          secrets = {
            "passwords/${constants.users.admin}" = {
              neededForUsers = true;
            };
          };
        };
      };
      esquire = {
        includes = [ <secrets/sops> ];

        homeManager = mkHomeManagerSops {
          withSshInclude = true;
          secrets = {
            "ssh/config" = { };
            "keys/ssh/github/signing/ghspy-pub" = {
              sopsFile = hostSopsFile.esquire;
            };
            "keys/pat/ghspy-pat" = {
              sopsFile = hostSopsFile.esquire;
            };
          };
        };
        nixos = mkNixosSops {
          defaultSopsFile = hostSopsFile.esquire;
          secrets = {
            "keys/ssh/github/auth/ghspy-pub" = {
              name = "ghspy-auth.pub";
              path = "/home/${constants.users.seraphyne}/.ssh_keys/ghspy-auth.pub";
              owner = "${constants.users.seraphyne}";
              mode = "0600";
            };
            "keys/ssh/github/auth/ghcny-pub" = {
              name = "ghcny-auth.pub";
              path = "/home/${constants.users.seraphyne}/.ssh_keys/ghcny-auth.pub";
              owner = "${constants.users.seraphyne}";
              mode = "0600";
            };
            "passwords/${constants.users.seraphyne}" = {
              sopsFile = sharedSopsFile;
              neededForUsers = true;
            };
            "keys/ssh/workstation/users/${constants.users.seraphyne}" = {
              sopsFile = sharedSopsFile;
            };
          };
        };
      };

      acerus = {
        includes = [ <secrets/sops> ];

        homeManager = mkHomeManagerSops {
          withSshInclude = true;
          secrets = {
            "ssh/config" = { };
            "keys/ssh/github/signing/ghspy-pub" = {
              sopsFile = hostSopsFile.acerus;
            };
          };
        };

        nixos = mkNixosSops {
          defaultSopsFile = hostSopsFile.acerus;
          secrets = {
            "keys/ssh/github/auth/ghspy-pub" = {
              name = "ghspy-auth.pub";
              path = "/home/${constants.users.seraphyne}/.ssh_keys/ghspy-auth.pub";
              owner = "${constants.users.seraphyne}";
              mode = "0600";
            };
            "passwords/${constants.users.seraphyne}" = {
              sopsFile = sharedSopsFile;
              neededForUsers = true;
            };
            "passwords/${constants.users.micha}" = {
              sopsFile = sharedSopsFile;
              neededForUsers = true;
            };
            "keys/ssh/workstation/users/${constants.users.seraphyne}" = {
              sopsFile = sharedSopsFile;
            };
            "keys/ssh/workstation/users/${constants.users.micha}" = {
              sopsFile = sharedSopsFile;
            };
          };
        };
      };

      mbp = {
        includes = [ <secrets/sops> ];

        homeManager = mkHomeManagerSops {
          secrets = {
            "keys/ssh/github/signing/ghcny-pub" = {
              sopsFile = hostSopsFile.mbp;
            };
          };
        };

        nixos = mkNixosSops {
          defaultSopsFile = hostSopsFile.mbp;
          secrets = {
            "keys/ssh/workstation/users/${constants.users.chianyung}" = {
              sopsFile = sharedSopsFile;
            };
          };
        };

        darwin =
          args@{ config, pkgs, ... }:
          let
            userHome =
              config.users.users.${constants.users.chianyung}.home or "/Users/${constants.users.chianyung}";
          in
          mkDarwinSops {
            defaultSopsFile = hostSopsFile.mbp;
            extraPackages = [ pkgs.ssh-to-age ];
            age = {
              keyFile = "${userHome}/.local/share/ages/keys.txt";
              generateKey = true;
            };
            secrets = {
              "keys/ssh/github/auth/ghspy-pub" = {
                name = "ghspy-pub";
                sopsFile = sharedSopsFile;
                path = "${userHome}/.ssh_keys/ghspy.pub";
                owner = "${constants.users.chianyung}";
                mode = "0600";
              };

              "passwords/${constants.users.chianyung}" = {
                sopsFile = sharedSopsFile;
                neededForUsers = true;
              };
            };
          } args;
      };
    };
  };
}
