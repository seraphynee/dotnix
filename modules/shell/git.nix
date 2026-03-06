{ lib, __findFile, ... }:
let
  mkConventionalAlias =
    type:
    "!a() {\nlocal _scope _attention _message\nwhile [ $# -ne 0 ]; do\ncase $1 in\n  -s | --scope )\n    if [ -z $2 ]; then\n      echo \"Missing scope!\"\n      return 1\n    fi\n    _scope=\"$2\"\n    shift 2\n    ;;\n  -a | --attention )\n    _attention=\"!\"\n    shift 1\n    ;;\n  * )\n    _message=\"\${_message} $1\"\n    shift 1\n    ;;\nesac\ndone\ngit commit -m \"${type}\${_scope:+(\${_scope})}\${_attention}:\${_message}\"\n}; a";

  mkGitProfile =
    {
      gitUser,
      gitEmail,
      githubUser,
      signingKey,
    }:
    {
      pkgs,
      ...
    }:
    let
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
      githubPrefix = if gitUser == "seraphynee" then "ghspy:" else "ghcny:";
    in
    {
      programs.git = {
        enable = true;
        userName = gitUser;
        userEmail = gitEmail;

        aliases = {
          co = "checkout";
          pf = "!git push --force-with-lease \"$@\"";
          cam = "commit --amend --no-edit";

          dl = "-c diff.external=difft log -p --ext-diff";
          ds = "-c diff.external=difft show --ext-diff";
          dft = "-c diff.external=difft diff";

          build = mkConventionalAlias "build";
          chore = mkConventionalAlias "chore";
          ci = mkConventionalAlias "ci";
          docs = mkConventionalAlias "docs";
          feat = mkConventionalAlias "feat";
          fix = mkConventionalAlias "fix";
          perf = mkConventionalAlias "perf";
          refactor = mkConventionalAlias "refactor";
          rev = mkConventionalAlias "revert";
          style = mkConventionalAlias "style";
          test = mkConventionalAlias "test";
          wip = mkConventionalAlias "wip";
        };

        signing = {
          key = signingKey;
          signByDefault = true;
        };

        extraConfig = {
          gpg.format = "ssh";
          "gpg \"ssh\"".program =
            if isDarwin then
              "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
            else
              "${lib.getExe' pkgs._1password-gui "op-ssh-sign"}";

          core = {
            pager = "delta";
            excludesFile = "~/.config/git/ignore";
            whitespace = "space-before-tab,-indent-with-non-tab,trailing-space";
            precomposeunicode = false;
          };

          init = {
            default = "branch";
            defaultBranch = "main";
          };

          credential = {
            helper = lib.optionals isDarwin [ "osxkeychain" ] ++ [
              "/usr/local/share/gcm-core/git-credential-manager"
            ];
            "https://github.com".username = githubUser;
            "https://dev.azure.com".useHttpPath = true;
          }
          // lib.optionalAttrs (!isDarwin) {
            credentialStore = "cache";
            guiPrompt = false;
          };

          url = {
            "${githubPrefix}".insteadOf = "https://github.com/";
            "glcny:".insteadOf = "https://gitlab.com/";
          };

          delta = {
            navigate = true;
            side-by-side = true;
            syntax-theme = "DarkNeon";
            plus-style = "syntax #445345";
            minus-style = "syntax #4F221F";
            line-numbers = true;
          };

          interactive.diffFilter = "delta --color-only";
          merge.conflictstyle = "zdiff3";
          diff = {
            colorMoved = "default";
            external = "difft";
            tool = "difftastic";
          };
          difftool = {
            prompt = false;
            "difftastic".cmd =
              "difft \"$MERGED\" \"$LOCAL\" \"abcdef1\" \"100644\" \"$REMOTE\" \"abcdef2\" \"100644\"";
          };

          apply.whitespace = "fix";
          branch.sort = "-committerdate";
          color = {
            ui = true;
            branch = {
              current = "yellow reverse";
              local = "yellow";
              remote = "green";
            };
          };

          fetch = {
            prune = true;
            pruneTags = true;
            all = true;
          };
          push.default = "current";
          pull.rebase = true;
          rebase = {
            autosquash = true;
            autostash = true;
            updateRefs = true;
          };

          pager = {
            status = true;
            show-branch = true;
            difftool = true;
          };

          "filter \"lfs\"" = {
            clean = "git-lfs clean -- %f";
            smudge = "git-lfs smudge -- %f";
            process = "git-lfs filter-process";
            required = true;
          };
        };
      };
    };
in
{
  den.aspects.shell._.git = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          delta
          difftastic
          git-lfs
        ];
      };

    provides = {
      chianyungcode = {
        includes = [ <shell/git> ];

        homeManager = mkGitProfile {
          gitUser = "chianyungcode";
          gitEmail = "cnytechcode@gmail.com";
          githubUser = "chianyungcode";
          signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINWQKPz2Bz5ufdBQih3CFMXhpg21Rwzgy/RaT+Q0XNwS";
        };
      };

      seraphyne = {
        includes = [ <shell/git> ];

        homeManager = mkGitProfile {
          gitUser = "seraphynee";
          gitEmail = "seraphyne31@gmail.com";
          githubUser = "seraphynee";
          signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINWQKPz2Bz5ufdBQih3CFMXhpg21Rwzgy/RaT+Q0XNwS";
        };
      };
    };
  };
}
