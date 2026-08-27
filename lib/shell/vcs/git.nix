{
  config,
  lib,
  pkgs,
  ...
}:
let
  mkConventionalAlias =
    type:
    "!a() {\nlocal _scope _attention _message\nwhile [ $# -ne 0 ]; do\ncase $1 in\n  -s | --scope )\n    if [ -z $2 ]; then\n      echo \"Missing scope!\"\n      return 1\n    fi\n    _scope=\"$2\"\n    shift 2\n    ;;\n  -a | --attention )\n    _attention=\"!\"\n    shift 1\n    ;;\n  * )\n    _message=\"\${_message} $1\"\n    shift 1\n    ;;\nesac\ndone\ngit commit -m \"${type}\${_scope:+(\${_scope})}\${_attention}:\${_message}\"\n}; a";

  mkGitProfile =
    {
      gitUser,
      gitEmail,
      githubUser ? null,
      githubPAT ? null,
      signingKeySecret ? null,
    }:
    {
      pkgs,
      config,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) isDarwin;
      githubPATPath =
        if githubPAT == null then
          null
        else
          lib.attrByPath [
            "sops"
            "secrets"
            githubPAT
            "path"
          ] null config;
      signingKeyPath =
        if signingKeySecret == null then
          null
        else
          lib.attrByPath [
            "sops"
            "secrets"
            signingKeySecret
            "path"
          ] null config;
    in
    {
      home.sessionVariables = lib.optionalAttrs (githubPATPath != null) {
        GITHUB_TOKEN_FILE = githubPATPath;
      };

      xdg.configFile."git/ignore".source = ../../../dots/config/git/ignore;

      programs.bash.bashrcExtra = lib.mkIf (githubPATPath != null) (
        lib.mkAfter ''
          if [ -r "${githubPATPath}" ]; then
            export GITHUB_TOKEN="$(cat "${githubPATPath}")"
          fi
        ''
      );

      programs.git = {
        enable = true;
        signing = lib.optionalAttrs (signingKeyPath != null) {
          key = signingKeyPath;
          signByDefault = true;
        };

        settings = {
          user = {
            name = gitUser;
            email = gitEmail;
          };

          alias = {
            co = "checkout";
            pf = "!git push --force-with-lease \"$@\"";
            cam = "commit --amend --no-edit";

            "log-patch" = "-c diff.external=difft log -p --ext-diff --stat";
            sh = "-c diff.external=difft show --ext-diff";

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
            "https://dev.azure.com".useHttpPath = true;
          }
          // lib.optionalAttrs (githubUser != null) {
            "https://github.com".username = githubUser;
          }
          // lib.optionalAttrs (!isDarwin) {
            credentialStore = "cache";
            guiPrompt = false;
          };

          # Disable this because when starting noctalia-shell plugins it's needed to run git clone operations and when this activated it neeeded to approve prompt for 1Password
          # url = {
          #   "${githubPrefix}".insteadOf = "https://github.com/";
          #   "glcny:".insteadOf = "https://gitlab.com/";
          # };

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
  cfg = config.dotnix.vcs;
  gitProfile = {
    gitUser = cfg.identity.name;
    gitEmail = cfg.identity.email;
    githubUser = cfg.github.username;
    githubPAT = cfg.github.patSecret;
    signingKeySecret = cfg.signing.keySecret;
  };
in
{
  config = lib.mkIf cfg.git.enable (
    lib.mkMerge [
      ((mkGitProfile gitProfile) { inherit config pkgs; })
      {
        home.packages = with pkgs; [
          delta
          difftastic
          gh
          gitleaks
          gitui
          git-lfs
          onefetch
          tig
        ];
      }
    ]
  );
}
