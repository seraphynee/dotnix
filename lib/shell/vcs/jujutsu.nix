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
        };
      }
    ]
  );
}
