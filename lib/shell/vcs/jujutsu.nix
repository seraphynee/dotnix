{
  config,
  lib,
  pkgs,
  ...
}:
let
  mkJujutsuProfile =
    {
      gitUser,
      gitEmail,
      signingKeySecret ? null,
      workstation ? false,
      bookmarkPrefix,
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
            "default-command" = [
              "log"
              "-r"
              "@"
              "--no-graph"
              "-p"
              "-s"
            ];
            "diff-editor" = "gitpatch";
            "merge-editor" = "diffconflicts";
            editor = "nvim";
          }
          // lib.optionalAttrs workstation {
            "diff-formatter" = [
              "difft"
              "--color=always"
              "$left"
              "$right"
            ];
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

          "merge-tools".diffconflicts = {
            program = "nvim";
            "merge-args" = [
              "-c"
              "let g:jj_diffconflicts_marker_length=$marker_length"
              "-c"
              "JJDiffConflicts!"
              "$output"
              "$base"
              "$left"
              "$right"
            ];
            "merge-tool-edits-conflict-markers" = true;
          };

          remotes.origin."auto-track-bookmarks" = "glob:*";

          signing =
            if signingKeyPath != null then
              {
                behavior = "own";
                backend = "ssh";
                key = signingKeyPath;
              }
            else
              {
                behavior = "drop";
                backend = "none";
              };

          templates.git_push_bookmark = "\"${bookmarkPrefix}/push-\" ++ change_id.short()";

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
            # Hack when waiting for https://github.com/jj-vcs/jj/issues/405
            # pre-committed commit
            pco = [
              "util"
              "exec"
              "--"
              "bash"
              "-c"
              ''
                set -euo pipefail

                # List files changed in the current working commit (`@`)
                changed_files=$(jj diff --name-only -r @)

                # If nothing changed, just commit normally
                if [ -z "$changed_files" ]; then
                  exec jj commit "$@"
                fi

                # Run pre-commit only on the changed files
                printf '%s\n' "$changed_files" | xargs pre-commit run --files

                # If pre-commit succeeded, create the commit
                exec jj commit "$@"
              ''
              ""
            ];

            # Run pre-commit before editing the current commit description
            pde = [
              "util"
              "exec"
              "--"
              "bash"
              "-c"
              ''
                set -euo pipefail

                # List files changed in the current working commit (`@`)
                changed_files=$(jj diff --name-only -r @)

                # If nothing changed, just edit the current commit description
                if [ -z "$changed_files" ]; then
                  exec jj describe --editor "$@"
                fi

                # Run pre-commit only on the changed files
                printf '%s\n' "$changed_files" | xargs pre-commit run --files

                # If pre-commit succeeded, edit the current commit description
                exec jj describe --editor "$@"
              ''
              ""
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
            wl = [
              "workspace"
              "list"
            ];
            wa = [
              "util"
              "exec"
              "--"
              "bash"
              "-c"
              ''
                set -euo pipefail
                root=$(jj workspace root)
                base=$(basename "$root")
                name="$base.$0"
                dest="$(dirname "$root")/$name"
                jj workspace add --name "$name" --revision main "$dest"
              ''
            ];
            wacd = [
              "util"
              "exec"
              "--"
              "bash"
              "-c"
              ''
                set -euo pipefail
                arg="$0"
                if [ -z "$arg" ]; then
                  echo "usage: jj wacd <workspace>" >&2
                  exit 2
                fi
                root=$(jj workspace root)
                base=$(basename "$root")
                name="$base.$arg"
                dest="$(dirname "$root")/$name"
                jj workspace add --name "$name" --revision main "$dest" 1>&2
                printf '%s\n' "$dest"
              ''
            ];
            wq = [
              "util"
              "exec"
              "--"
              "bash"
              "-c"
              ''
                set -euo pipefail
                root=$(jj workspace root)
                repo="$root/.jj/repo"
                if [ -f "$repo" ]; then
                  repo_ref=$(cat "$repo")
                  shared_repo=$(cd "$root/.jj" && cd "$repo_ref" && pwd -P)
                  root=$(dirname "$(dirname "$shared_repo")")
                fi
                printf '%s\n' "$root"
              ''
            ];
            wcd = [
              "util"
              "exec"
              "--"
              "bash"
              "-c"
              ''
                set -euo pipefail
                arg="$0"
                if [ -z "$arg" ]; then
                  echo "usage: jj wcd <workspace>" >&2
                  exit 2
                fi
                if dest=$(jj workspace root --name "$arg" 2>/dev/null); then
                  printf '%s\n' "$dest"
                else
                  root=$(jj wq)
                  base=$(basename "$root")
                  jj workspace root --name "$base.$arg"
                fi
              ''
            ];
            wd = [
              "util"
              "exec"
              "--"
              "bash"
              "-c"
              ''
                set -euo pipefail
                arg="$0"
                if dest=$(jj workspace root --name "$arg" 2>/dev/null); then
                  name="$arg"
                else
                  root=$(jj workspace root --name default 2>/dev/null || jj workspace root)
                  base=$(basename "$root")
                  name="$base.$arg"
                  dest=$(jj workspace root --name "$name")
                fi
                if [ "$name" = "default" ]; then
                  echo "refusing to forget/delete the default workspace" >&2
                  exit 1
                fi
                jj workspace forget "$name"
                rm -rf -- "$dest"
                echo "Forgot and deleted workspace: $name ($dest)"
              ''
            ];
          };

          snapshot."auto-update-stale" = true;

          lazyjj = {
            "layout-percent" = 30;
          }
          // lib.optionalAttrs workstation {
            "diff-tool" = "difft";
          };
        };
      };
    };
  cfg = config.dotnix.vcs;
  bookmarkPrefix =
    if cfg.jujutsu.bookmarkPrefix != null then
      cfg.jujutsu.bookmarkPrefix
    else if cfg.github.username != null then
      cfg.github.username
    else
      cfg.identity.name;
  workstation = cfg.jujutsu.workstation;
  jujutsuProfile = {
    gitUser = cfg.identity.name;
    gitEmail = cfg.identity.email;
    signingKeySecret = cfg.signing.keySecret;
    inherit workstation;
    inherit bookmarkPrefix;
  };
in
{
  config = lib.mkIf cfg.jujutsu.enable (
    lib.mkMerge [
      ((mkJujutsuProfile jujutsuProfile) { inherit config; })
      {
        home.packages = with pkgs; [
          koji
          lazyjj
        ];

        programs = {
          jjui = {
            enable = true;
            settings = {
              preview = {
                position = "bottom";
                show_at_start = true;
              };

              ui = {
                # theme = "onedark-dark";
                tracer = {
                  enabled = true;
                };
              };

              leader = {
                bn = {
                  help = "Set new bookmark";
                  send = [
                    "$"
                    ''jj bookmark set -r "$change_id" $(gum input --placeholder "Name of the new bookmark")''
                    "enter"
                  ];
                };
              };
            };
          };

          fish.interactiveShellInit = lib.mkAfter ''
            # Jujutsu
            abbr -a j jj # I use `jj` to exit insert mode
            abbr -a jh 'jj -h'
            abbr -a ji jjui

            abbr -a jst 'jj status'
            abbr -a jab --set-cursor 'jj abandon %'
            abbr -a jabso 'jj absorb'
            abbr -a je --set-cursor 'jj edit %'

            abbr -a jsh --set-cursor 'jj show -r "@%"'
            abbr -a jshs --set-cursor 'jj show -s -r "@%"'
            abbr -a jshst --set-cursor 'jj show -r "@%" --stat'

            abbr -a jbl 'jj bookmark list -a'
            abbr -a jbm --set-cursor 'jj bookmark move % --to @-'
            abbr -a jbmm 'jj bookmark move main --to @-'
            abbr -a jbsc 'jj bookmark set -r @'

            abbr -a jdf --set-cursor 'jj diff -r "@%"'
            abbr -a jdfs --set-cursor 'jj diff -s -r "@%"'

            abbr -a jgf 'jj git fetch'
            abbr -a jgpa 'jj git push'
            abbr -a jgps --set-cursor 'jj git push -b %'
            abbr -a jgpsm --set-cursor 'jj git push -b main'

            abbr -a jl 'jj log'
            abbr -a jla "jj log 'all()'"
            abbr -a jlt --set-cursor "jj log -T %"
            abbr -a jls --set-cursor 'jj log -s'
            abbr -a jlsr --set-cursor 'jj log -s -r "@%"'
            abbr -a jlsp --set-cursor 'jj log -s -p'
            abbr -a jlspr --set-cursor 'jj log -s -p -r "@%"'
            abbr -a jlp --set-cursor 'jj log -p'
            abbr -a jlps --set-cursor 'jj log -p -s'
            abbr -a jlpsr --set-cursor 'jj log -p -s -r "@%"'

            abbr -a jrs --set-cursor 'jj restore %'
            abbr -a jrsi 'jj restore -i'

            abbr -a jrb --set-cursor 'jj rebase %'
            abbr -a jrbh --set-cursor 'jj rebase -h'
            abbr -a jrbs --set-cursor 'jj rebase -s % -o @-'
            abbr -a jrbr --set-cursor 'jj rebase -r % -o %'

            abbr -a jsp --set-cursor 'jj split -r "@%"'
            abbr -a jspi --set-cursor 'jj split -i -r "@%"'
            abbr -a jspa --set-cursor 'jj split -A %'
            abbr -a jspb --set-cursor 'jj split -B %'

            abbr -a jsq --set-cursor 'jj squash -r "@%"'
            abbr -a jsqi --set-cursor 'jj squash -i -r "@%"'
            abbr -a jsqft --set-cursor 'jj squash -f "@%" -t "%"'
            abbr -a jsqift --set-cursor 'jj squash -i -f "@%" -t "%"'

            abbr -a jd --set-cursor 'jj desc -m "%" -r "@%"'
            abbr -a jdc --set-cursor 'jj desc -m "$(koji --stdout)" -r "@%"'

            abbr -a jc 'jj commit'
            abbr -a jcc 'jj commit -m "$(koji --stdout)"'

            abbr -a jn --set-cursor 'jj new %'
            abbr -a jna --set-cursor 'jj new -A %'
            abbr -a jnb --set-cursor 'jj new -B %'
            abbr -a jnc 'jj new -m "$(koji --stdout)"'

            abbr -a judo 'jj undo'
            abbr -a jop --set-cursor 'jj op %'
            abbr -a jopl --set-cursor 'jj op log %'
            abbr -a jopd --set-cursor 'jj op diff %'
            abbr -a jopa --set-cursor 'jj op abandon %'
            abbr -a joprs --set-cursor 'jj op restore %'
            abbr -a joprv --set-cursor 'jj op revert %'
            abbr -a jevl --set-cursor 'jj evolog -r "@%"'
            abbr -a jevlp --set-cursor 'jj evolog -p -r "@%"'
          '';

        };
      }
    ]
  );
}
