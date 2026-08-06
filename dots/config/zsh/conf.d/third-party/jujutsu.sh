if (( $+commands[jj] )); then
  jj() {
    case ${1-} in
      wq|wcd|wacd) local destination; destination=$(command jj "$@") || return; [[ -d $destination ]] || { print -u2 "jj: workspace directory does not exist: $destination"; return 1; }; cd -- "$destination";;
      *) command jj "$@";;
    esac
  }
fi
