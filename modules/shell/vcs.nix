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
    ../../lib/shell/vcs/repositories.nix
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
      {
        pkgs,
        lib,
        ...
      }:
      let
        worktrunk = inputs.worktrunk.packages.${pkgs.stdenv.hostPlatform.system}.default;
        worktrunkFishCompletion = pkgs.runCommand "worktrunk-fish-completion" { } ''
          ${worktrunk}/bin/wt config shell completions fish > $out
        '';
        worktrunkFishIntegration = pkgs.runCommand "worktrunk-fish-integration" { } ''
          ${worktrunk}/bin/wt config shell init fish > $out
        '';
        worktrunkZshIntegration = pkgs.runCommand "worktrunk-zsh-integration" { } ''
          ${worktrunk}/bin/wt config shell init zsh > $out
        '';
        worktrunkBashIntegration = pkgs.runCommand "worktrunk-bash-integration" { } ''
          ${worktrunk}/bin/wt config shell init bash > $out
        '';
      in
      {
        home.packages = [ worktrunk ];
        xdg.configFile."fish/completions/wt.fish".source = worktrunkFishCompletion;
        xdg.configFile."fish/functions/wt.fish".source = worktrunkFishIntegration;
        # Sourced by the existing conf.d glob in modules/shell/shells.nix;
        # includes its own lazy completion via compdef.
        xdg.configFile."zsh/conf.d/080-worktrunk.zsh".source = worktrunkZshIntegration;
        programs.bash.bashrcExtra = lib.mkAfter ''
          source ${worktrunkBashIntegration}
        '';
      };
  };
}
