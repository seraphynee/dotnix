{
  paths,
  __findFile,
  inputs,
  lib,
  ...
}:
{
  # Version control
  den.aspects.shell._.vcs.homeManager.imports = [
    ../../lib/shell/vcs/profile.nix
    (import ../../lib/shell/vcs/git.nix { inherit paths; })
    ../../lib/shell/vcs/jujutsu.nix
    ../../lib/shell/vcs/repositories.nix
  ];
  den.aspects.shell._.vcs.includes = [ <shell/jj-waltz> ];
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

      xdg.configFile."hunk/config.toml".source = paths.dots + "/config/hunk/config.toml";
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
  # jj-waltz (`jw`): Jujutsu workspace switcher
  den.aspects.shell._.jj-waltz.homeManager =
    {
      lib,
      pkgs,
      ...
    }:
    let
      jw = pkgs.callPackage ../../pkgs/jj-waltz/package.nix { src = inputs.jj-waltz; };
      # Shell init is generated at build time. The completions line is dropped
      # because the static completion files below already provide (lazy)
      # completions, same as the chezmoi setup.
      jwFishInit = pkgs.runCommand "jw-fish-init.fish" { } ''
        ${lib.getExe jw} shell init fish | grep -vF 'jw shell completions fish' > "$out"
      '';
      jwZshInit = pkgs.runCommand "jw-zsh-init.zsh" { } ''
        ${lib.getExe jw} shell init zsh | grep -vF 'jw shell completions zsh' > "$out"
      '';
      # `site-functions` of the profile is already on zsh's fpath (home-manager).
      jwZshCompletion = pkgs.writeTextDir "share/zsh/site-functions/_jw" (
        builtins.readFile (paths.dots + "/config/zsh/completions/_jw")
      );
    in
    {
      home.packages = [
        jw
        jwZshCompletion
      ];
      xdg.configFile."fish/completions/jw.fish".source = paths.dots + "/config/fish/completions/jw.fish";
      programs.fish.interactiveShellInit = lib.mkAfter ''
        source ${jwFishInit}
      '';
      programs.zsh.initContent = lib.mkAfter ''
        source ${jwZshInit}
      '';
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
        # Sourced by the existing conf.d glob in modules/shell/shells/zsh.nix;
        # includes its own lazy completion via compdef.
        xdg.configFile."zsh/conf.d/080-worktrunk.zsh".source = worktrunkZshIntegration;
        programs.bash.bashrcExtra = lib.mkAfter ''
          source ${worktrunkBashIntegration}
        '';
      };
  };
}
