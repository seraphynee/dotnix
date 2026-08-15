if [[ -o interactive ]] && (( $+commands[sk] && $+commands[fd] )); then
  skim-ctrl-t-widget() {
    local query=${LBUFFER##* } prefix=$LBUFFER item
    local -a selected result files

    while true; do
      result=("${(@f)$(
        fd --hidden --exclude .git --type f --type d --type symlink |
          sk --border=rounded --regex --multi --reverse --header='CTRL-E edit marked files | CTRL-C bat marked files | CTRL-D cd directory' --bind 'ctrl-e:accept(ctrl-e)' --bind 'ctrl-c:accept(ctrl-c)' --bind 'ctrl-d:accept(ctrl-d)' --bind 'ctrl-q:abort' --query "$query"
      )}")

      if (( ! ${#result} )); then
        break
      fi

      if [[ "${result[1]}" == ctrl-e || "${result[1]}" == ctrl-c ]]; then
        files=()
        if (( ${#result} > 1 )); then
          for item in "${(@)result[2,-1]}"; do
            [[ -f "$item" ]] && files+=("$item")
          done
        fi

        if (( ${#files} )); then
          if [[ "${result[1]}" == ctrl-e ]]; then
            local editor="${EDITOR:-vim}"
            ${=editor} -- "${files[@]}"
          else
            bat --color=always -- "${files[@]}"
          fi
        fi

        selected=()
        break
      fi

      if [[ "${result[1]}" == ctrl-d ]]; then
        if (( ${#result} > 1 )) && [[ -d "${result[2]}" ]]; then
          cd -- "${result[2]}" || continue
          query=""
        fi
        continue
      fi

      selected=("${result[@]}")
      break
    done

    (( ${#selected} )) || { zle reset-prompt 2>/dev/null || true; return; }
    [[ $query != $LBUFFER ]] && prefix=${LBUFFER[1,$(( $#LBUFFER - $#query ))]}
    LBUFFER=$prefix
    for item in "${selected[@]}"; do LBUFFER+="${(q)item} "; done
    zle reset-prompt 2>/dev/null || true
  }
  zle -N skim-ctrl-t-widget
  bindkey '^T' skim-ctrl-t-widget; bindkey -M viins '^T' skim-ctrl-t-widget
fi
