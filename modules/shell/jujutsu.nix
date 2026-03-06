{ __findFile, lib, ... }:
let
  mkJujutsuProfile =
    {
      gitUser,
      gitEmail,
      signingKeySecret ? null,
    }:
    { config, ... }:
    let
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
      programs.jujutsu = {
        enable = true;
        settings = {
          user = {
            name = gitUser;
            email = gitEmail;
          };

          ui = {
            "default-command" = "log";
            "diff-formatter" = [
              "difft"
              "--color=always"
              "$left"
              "$right"
            ];
            "diff-editor" = "gitpatch";
            editor = "nvim";
          };

          "merge-tools".gitpatch = {
            program = "sh";
            "edit-args" = [
              "-c"
              ''
                set -eu
                rm -f "$right/JJ-INSTRUCTIONS"
                git -C "$left" init -q
                git -C "$left" add -A
                git -C "$left" commit -q -m baseline --allow-empty
                mv "$left/.git" "$right"
                git -C "$right" add --intent-to-add --ignore-removal .
                git -C "$right" add -p
                git -C "$right" diff-index --quiet --cached HEAD && { echo "No changes done, aborting split."; exit 1; }
                git -C "$right" commit -q -m split
                git -C "$right" reset -q --hard
              ''
            ];
          };

          remotes.origin."auto-track-bookmarks" = "glob:*";

          signing = {
            behavior = "own";
            backend = "ssh";
          }
          // lib.optionalAttrs (signingKeyPath != null) {
            key = signingKeyPath;
          };

          templates.git_push_bookmark = "\"${gitUser}/push-\" ++ change_id.short()";

          "template-aliases" = {
            commit_change_ids = ''
              concat(
                format_field("Change ID", change_id.short(8)),
                format_field("Commit ID", commit_id.short(7)),
              )
            '';
            oneline_log = "separate(\" \", change_id.shortest(8), description.first_line(), commit_id.shortest(7))";
          };

          aliases = {
            ed = [ "edit" ];
            la = [
              "log"
              "-r"
              "all()"
            ];
            abd = [ "abandon" ];
            fetch = [
              "git"
              "fetch"
            ];
            init = [
              "git"
              "init"
              "--colocate"
            ];
            mark = [
              "bookmark"
              "set"
              "-r"
            ];
            markc = [
              "bookmark"
              "set"
              "-r"
              "@"
            ];
            push = [
              "git"
              "push"
              "--allow-new"
            ];
            track = [
              "bookmark"
              "track"
            ];
          };

          lazyjj = {
            "diff-tool" = "difft";
            "layout-percent" = 30;
          };
        };
      };
    };
in
{
  den.aspects.shell._.jujutsu = {
    homeManager = {
      programs.fish.interactiveShellInit = lib.mkAfter ''
        # Jujutsu
        abbr -a j jj # I use `jj` to exit insert mode
        abbr -a jh 'jj -h'

        abbr -a jst 'jj status'
        abbr -a jsh --set-cursor 'jj show %'

        abbr -a jbl 'jj bookmark list -a'
        abbr -a jbm --set-cursor 'jj bookmark move % --to @-'
        abbr -a jbmm 'jj bookmark move main --to @-'
        abbr -a jbsc 'jj bookmark set -r @'

        abbr -a jdf 'jj diff'
        abbr -a je --set-cursor 'jj edit %'

        abbr -a jgf 'jj git fetch'
        abbr -a jgpa 'jj git push'
        abbr -a jgps --set-cursor 'jj git push -b %'
        abbr -a jgpsm --set-cursor 'jj git push -b main'

        abbr -a jl 'jj log'
        abbr -a jla "jj log 'all()'"
        abbr -a jlt --set-cursor "jj log -T %"

        abbr -a jrh --set-cursor 'jj rebase -h'
        abbr -a jrs --set-cursor 'jj rebase -s % -d @-'
        abbr -a jrr --set-cursor 'jj rebase -r % -o '

        abbr -a jsp 'jj split'
        abbr -a jspi 'jj split -i'

        abbr -a jsq 'jj squash'
        abbr -a jsqi 'jj squash -i'
        abbr -a jsqc --set-cursor 'jj squash -t %'

        abbr -a jab --set-cursor 'jj abandon %'

        abbr -a jd --set-cursor 'jj desc -m "%"'
        abbr -a jdc 'jj desc -m "$(koji --stdout)"'

        abbr -a jc 'jj commit'
        abbr -a jcc 'jj commit -m "$(koji --stdout)"'

        abbr -a jn --set-cursor 'jj new %'
        abbr -a jnc 'jj new -m "$(koji --stdout)"'

        abbr -a judo 'jj undo'
        abbr -a jopl 'jj op log'
        abbr -a jevl 'jj evolog'
      '';

    };
    provides = {
      chianyungcode = {
        includes = [ <shell/jujutsu> ];

        homeManager = mkJujutsuProfile {
          gitUser = "chianyungcode";
          gitEmail = "cnytechcode@gmail.com";
          signingKeySecret = "ssh/keys/signing/ghcny-pub";
        };
      };

      seraphyne = {
        includes = [ <shell/jujutsu> ];

        homeManager = mkJujutsuProfile {
          gitUser = "seraphynee";
          gitEmail = "seraphyne31@gmail.com";
          signingKeySecret = "ssh/keys/signing/ghspy-pub";
        };
      };
    };
  };
}
