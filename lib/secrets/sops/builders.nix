{
  lib,
  inputs,
  paths,
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
  sharedSopsFile = paths.secrets + "/shared/secrets.yaml";
  hostSopsFile = {
    esquire = paths.secrets + "/esquire/secrets.yaml";
    mbp = paths.secrets + "/mbp/secrets.yaml";
    acerus = paths.secrets + "/acerus/secrets.yaml";
    vps = paths.secrets + "/vps/secrets.yaml";
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

  mkHomeManagerSops =
    {
      defaultSopsFile ? null,
      secrets ? { },
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
    } extraConfig;

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
  inherit
    mkHomeManagerSops
    mkNixosSops
    mkDarwinSops
    sharedSopsFile
    hostSopsFile
    ;
}
