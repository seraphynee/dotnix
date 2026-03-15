{
  lib,
  __findFile,
  constants,
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
      githubUser,
      githubPAT ? null,
      signingKeySecret,
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
      signingKeyPath = lib.attrByPath [
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

      programs.fish.interactiveShellInit = lib.mkIf (githubPATPath != null) (
        lib.mkAfter ''
          if test -r "${githubPATPath}"
            set -gx GITHUB_TOKEN (cat "${githubPATPath}")
          end
        ''
      );

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
in
{
  den.aspects.shell._.git =
    { user, ... }:
    let
      gitProfile =
        if user.userName == "${constants.user_one}" then
          {
            gitUser = "chianyungcode";
            gitEmail = "cnytechcode@gmail.com";
            githubUser = "chianyungcode";
            signingKeySecret = "keys/ssh/signing/ghcny-pub";
          }
        else if
          builtins.elem user.userName [
            "${constants.user_two}"
            "${constants.user_three}"
          ]
        then
          {
            gitUser = "seraphynee";
            gitEmail = "seraphyne31@gmail.com";
            githubUser = "seraphynee";
            githubPAT = "keys/pat/ghspy-pat";
            signingKeySecret = "keys/ssh/signing/ghspy-pub";
          }
        else
          throw "Unsupported git profile for user `${user.userName}` in modules/shell/git.nix";
    in
    {
      homeManager =
        { config, pkgs, ... }:
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

            programs.fish.interactiveShellInit = lib.mkAfter ''
              # git
              abbr --add g git
              abbr --add ga "git add"
              abbr --add gaa "git add --all"
              abbr --add gam "git am"
              abbr --add gama "git am --abort"
              abbr --add gamc "git am --continue"
              abbr --add gams "git am --skip"
              abbr --add gamscp "git am --show-current-patch"
              abbr --add gap "git apply"
              abbr --add gapa "git add --patch"
              abbr --add gapt "git apply --3way"
              abbr --add gau "git add --update"
              abbr --add gav "git add --verbose"
              abbr --add gb "git branch"
              abbr --add gba "git branch --all"
              abbr --add gbD "git branch --delete --force"
              abbr --add gbd "git branch --delete"
              abbr --add gbl "git blame -w"
              abbr --add gbm "git branch --move"
              abbr --add gbnm "git branch --no-merged"
              abbr --add gbr "git branch --remote"
              abbr --add gbs "git bisect"
              abbr --add gbsb "git bisect bad"
              abbr --add gbsg "git bisect good"
              abbr --add gbsn "git bisect new"
              abbr --add gbso "git bisect old"
              abbr --add gbsr "git bisect reset"
              abbr --add gbss "git bisect start"
              abbr --add gc "git commit --verbose"
              abbr --add gc\! "git commit --verbose --amend"
              abbr --add gca "git commit --verbose --all"
              abbr --add gca\! "git commit --verbose --all --amend"
              abbr --add gcam "git commit --all --message"
              abbr --add gcan\! 'git commit --verbose --all --no-edit --amend'
              abbr --add gcann\! 'git commit --verbose --all --date=now --no-edit --amend'
              abbr --add gcans\! 'git commit --verbose --all --signoff --no-edit --amend'
              abbr --add gcas "git commit --all --signoff"
              abbr --add gcasm "git commit --all --signoff --message"
              abbr --add gcB "git checkout -B"
              abbr --add gcb "git checkout -b"
              abbr --add gcd "git checkout \$(git_develop_branch)"
              abbr --add gcf "git config --list"
              abbr --add gcfu "git commit --fixup"
              abbr --add gcl "git clone --recurse-submodules"
              abbr --add gclean "git clean --interactive -d"
              abbr --add gclf "git clone --recursive --shallow-submodules --filter=blob:none --also-filter-submodules"
              abbr --add gcm "git checkout \$(git_main_branch)"
              abbr --add gcmsg "git commit --message"
              abbr --add gcn "git commit --verbose --no-edit"
              abbr --add gco "git checkout"
              abbr --add gcor "git checkout --recurse-submodules"
              abbr --add gcount "git shortlog --summary --numbered"
              abbr --add gcp "git cherry-pick"
              abbr --add gcp1 "ssh gcp1"
              abbr --add gcpa "git cherry-pick --abort"
              abbr --add gcpc "git cherry-pick --continue"
              abbr --add gcs "git commit --gpg-sign"
              abbr --add gcsm "git commit --signoff --message"
              abbr --add gcss "git commit --gpg-sign --signoff"
              abbr --add gcssm "git commit --gpg-sign --signoff --message"
              abbr --add gd "git diff"
              abbr --add gdca "git diff --cached"
              abbr --add gdct "git describe --tags \$(git rev-list --tags --max-count=1)"
              abbr --add gdcw "git diff --cached --word-diff"
              abbr --add gds "git diff --staged"
              abbr --add gdt "git diff-tree --no-commit-id --name-only -r"
              abbr --add gdup "git diff @{upstream}"
              abbr --add gdw "git diff --word-diff"
              abbr --add gf "git fetch"
              abbr --add gfa "git fetch --all --tags --prune --jobs=10"
              abbr --add gfg "git ls-files | grep"
              abbr --add gfo "git fetch origin"
              abbr --add gg "git gui citool"
              abbr --add gga "git gui citool --amend"
              abbr --add ggpur ggu
              abbr --add ggsup "git branch --set-upstream-to=origin/\$(git_current_branch)"
              abbr --add gignore "git update-index --assume-unchanged"
              abbr --add git-svn-dcommit-push "git svn dcommit && git push github \$(git_main_branch):svntrunk"
              abbr --add gk "\\gitk --all --branches &\!"
              abbr --add gke "\\gitk --all \$(git log --walk-reflogs --pretty=%h) &\!"
              abbr --add gl "git pull"
              abbr --add glab "op plugin run -- glab"
              abbr --add glg "git log --stat"
              abbr --add glgg "git log --graph"
              abbr --add glgga "git log --graph --decorate --branches --remotes --tags"
              abbr --add glggaa "git log --graph --decorate --all"
              abbr --add glgm "git log --graph --max-count=10"
              abbr --add glgp "git log --stat --patch"
              abbr --add glo "git log --oneline --decorate"
              abbr --add glod 'git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset"'
              abbr --add glods 'git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset" --date=short'
              abbr --add glog "git log --oneline --decorate --graph"
              abbr --add glogaa "git log --oneline --decorate --graph --all"
              abbr --add gloga "git log --oneline --decorate --graph --branches --remotes --tags"
              abbr --add glol 'git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
              abbr --add glolaa 'git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all'
              abbr --add glola 'git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --branches --remotes --tags'
              abbr --add glols 'git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --stat'
              abbr --add glp _git_log_prettily
              abbr --add gluc "git pull upstream \$(git_current_branch)"
              abbr --add glum "git pull upstream \$(git_main_branch)"
              abbr --add gm "git merge"
              abbr --add gma "git merge --abort"
              abbr --add gmc "git merge --continue"
              abbr --add gmff "git merge --ff-only"
              abbr --add gmom "git merge origin/\$(git_main_branch)"
              abbr --add gms "git merge --squash"
              abbr --add gmtl "git mergetool --no-prompt"
              abbr --add gmtlvim "git mergetool --no-prompt --tool=vimdiff"
              abbr --add gmum "git merge upstream/\$(git_main_branch)"
              abbr --add gp "git push"
              abbr --add gpd "git push --dry-run"
              abbr --add gpf "git push --force-with-lease --force-if-includes"
              abbr --add gpoat "git push origin --all && git push origin --tags"
              abbr --add gpod "git push origin --delete"
              abbr --add gpr "git pull --rebase"
              abbr --add gpra "git pull --rebase --autostash"
              abbr --add gprav "git pull --rebase --autostash -v"
              abbr --add gpristine "git reset --hard && git clean --force -dfx"
              abbr --add gprom "git pull --rebase origin \$(git_main_branch)"
              abbr --add gpromi "git pull --rebase=interactive origin \$(git_main_branch)"
              abbr --add gprum "git pull --rebase upstream \$(git_main_branch)"
              abbr --add gprumi "git pull --rebase=interactive upstream \$(git_main_branch)"
              abbr --add gprv "git pull --rebase -v"
              abbr --add gpsup "git push --set-upstream origin \$(git_current_branch)"
              abbr --add gpsupf "git push --set-upstream origin \$(git_current_branch) --force-with-lease --force-if-includes"
              abbr --add gpu "git push upstream"
              abbr --add gpv "git push --verbose"
              abbr --add gr "git remote"
              abbr --add gra "git remote add"
              abbr --add grb "git rebase"
              abbr --add grba "git rebase --abort"
              abbr --add grbc "git rebase --continue"
              abbr --add grbd "git rebase \$(git_develop_branch)"
              abbr --add grbi "git rebase --interactive"
              abbr --add grbm "git rebase \$(git_main_branch)"
              abbr --add grbo "git rebase --onto"
              abbr --add grbom "git rebase origin/\$(git_main_branch)"
              abbr --add grbs "git rebase --skip"
              abbr --add grbum "git rebase upstream/\$(git_main_branch)"
              abbr --add grev "git revert"
              abbr --add greva "git revert --abort"
              abbr --add grevc "git revert --continue"
              abbr --add grf "git reflog"
              abbr --add grh "git reset"
              abbr --add grhh "git reset --hard"
              abbr --add grhk "git reset --keep"
              abbr --add grhs "git reset --soft"
              abbr --add grm "git rm"
              abbr --add grmc "git rm --cached"
              abbr --add grmv "git remote rename"
              abbr --add groh "git reset origin/\$(git_current_branch) --hard"
              abbr --add grrm "git remote remove"
              abbr --add grs "git restore"
              abbr --add grset "git remote set-url"
              abbr --add grss "git restore --source"
              abbr --add grst "git restore --staged"
              abbr --add gru "git reset --"
              abbr --add grup "git remote update"
              abbr --add grv "git remote --verbose"
              abbr --add gsb "git status --short --branch"
              abbr --add gsd "git svn dcommit"
              abbr --add gsh "git show"
              abbr --add gsi "git submodule init"
              abbr --add gsps "git show --pretty=short --show-signature"
              abbr --add gsr "git svn rebase"
              abbr --add gss "git status --short"
              abbr --add gst "git status"
              abbr --add gsta "git stash push"
              abbr --add gstaa "git stash apply"
              abbr --add gstall "git stash --all"
              abbr --add gstc "git stash clear"
              abbr --add gstd "git stash drop"
              abbr --add gstl "git stash list"
              abbr --add gstp "git stash pop"
              abbr --add gsts "git stash show --patch"
              abbr --add gstu "gsta --include-untracked"
              abbr --add gsu "git submodule update"
              abbr --add gsw "git switch"
              abbr --add gswc "git switch --create"
              abbr --add gswd "git switch develop"
              abbr --add gswm "git switch main"
              abbr --add gta "git tag --annotate"
              abbr --add gts "git tag --sign"
              abbr --add gtv "git tag | sort -V"
              abbr --add gunignore "git update-index --no-assume-unchanged"
              abbr --add gwch "git whatchanged -p --abbrev-commit --pretty=medium"
              abbr --add gwipe "git reset --hard && git clean --force -df"
              abbr --add gwt "git worktree"
              abbr --add gwta "git worktree add"
              abbr --add gwtls "git worktree list"
              abbr --add gwtmv "git worktree move"
              abbr --add gwtrm "git worktree remove"
            '';
          }
        ];
    };
}
