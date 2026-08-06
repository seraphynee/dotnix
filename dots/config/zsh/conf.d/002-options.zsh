setopt always_to_end append_history auto_cd auto_list auto_menu auto_pushd complete_in_word extended_glob extended_history glob_dots hash_list_all hist_expire_dups_first hist_find_no_dups hist_ignore_dups hist_ignore_all_dups hist_save_no_dups hist_ignore_space hist_reduce_blanks hist_verify inc_append_history interactive_comments long_list_jobs no_beep nocaseglob nonomatch notify numeric_glob_sort prompt_subst pushd_ignore_dups share_history
unsetopt correct_all correct
typeset -U path cdpath fpath manpath
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=100000
SAVEHIST=$HISTSIZE
HISTDUP=erase
DISABLE_CORRECTION=true
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/cache"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu no
