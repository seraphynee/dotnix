{
  __findFile,
  inputs,
  lib,
  ...
}:
{
  # Version control
  den.aspects.shell._.vcs.homeManager.imports = [
    ../../lib/shell/vcs/profile.nix
    ../../lib/shell/vcs/git.nix
    ../../lib/shell/vcs/jujutsu.nix
  ];
  # Hunk
  den.aspects.shell._.hunk = {
    homeManager = {
      imports = [
        inputs.hunk.homeManagerModules.default
      ];

      programs.hunk = {
        enable = true;
        enableGitIntegration = false; # Optional: set hunk as default git pager
      };

      xdg.configFile."hunk/config.toml".source = ../../dots/config/hunk/config.toml;
    };
  };
  # Lazygit
  den.aspects.shell._.lazygit.homeManager = {
    programs.fish.interactiveShellInit = lib.mkAfter ''
      abbr --add lzg lazygit
    '';
    programs.lazygit = {
      enable = true;
      enableFishIntegration = false;
      settings = {
        git = {
          diffRenderers = [
            {
              type = "extDiff";
              command = "difft --color=always";
            }
          ];
        };
      };
    };
  };
  # OpenCommit
  den.aspects.shell._.opencommit = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ opencommit ];
      };
    homeManager =
      { config, pkgs, ... }:
      let
        ocoConfig =
          builtins.replaceStrings
            [
              "@oco_api_key@"
              "@oco_api_url@"
            ]
            [
              config.sops.placeholder."llm/oco_api_key"
              config.sops.placeholder."llm/oco_api_url"
            ]
            (builtins.readFile ../../dots/opencommit.tmpl);
      in
      {
        sops.templates."opencommit-config" = {
          path = "${config.home.homeDirectory}/.opencommit";
          mode = "0600";
          content = ocoConfig;
        };
      };
  };
  # Worktrunk
  den.aspects.shell._.worktrunk = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          inputs.worktrunk.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
      };
  };
}
