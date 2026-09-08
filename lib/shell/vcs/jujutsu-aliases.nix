{
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
}
