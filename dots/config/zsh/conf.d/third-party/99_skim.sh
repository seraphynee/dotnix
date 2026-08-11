if [[ -o interactive ]] && (( $+commands[sk] && $+commands[fd] )); then
  skim-ctrl-t-widget() {
    local query=${LBUFFER##* } prefix=$LBUFFER item
    local -a selected
    selected=("${(@f)$(fd --hidden --exclude .git --type f --type d --type symlink | sk --border=rounded --regex --multi --reverse --query "$query")}")
    (( ${#selected} )) || { zle reset-prompt 2>/dev/null || true; return; }
    [[ $query != $LBUFFER ]] && prefix=${LBUFFER[1,$(( $#LBUFFER - $#query ))]}
    LBUFFER=$prefix
    for item in "${selected[@]}"; do LBUFFER+="${(q)item} "; done
    zle reset-prompt 2>/dev/null || true
  }
  zle -N skim-ctrl-t-widget
  bindkey '^T' skim-ctrl-t-widget; bindkey -M viins '^T' skim-ctrl-t-widget
fi
