y() {
  (( $+commands[yazi] )) || return 127
  local tmp=$(mktemp -t yazi-cwd.XXXXXX) || return 1
  command yazi "$@" --cwd-file="$tmp"; local status=$?
  if [[ -r $tmp ]]; then local cwd=$(<"$tmp"); [[ -n $cwd && $cwd != $PWD && -d $cwd ]] && cd -- "$cwd"; fi
  rm -f -- "$tmp"; return $status
}
