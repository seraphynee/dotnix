export XDG_DATA_HOME=@XDG_DATA_HOME@
export XDG_CONFIG_HOME=@XDG_CONFIG_HOME@
export XDG_STATE_HOME=@XDG_STATE_HOME@
export XDG_CACHE_HOME=@XDG_CACHE_HOME@

typeset -a xdg_data_dirs=()
if [[ -n ${XDG_DATA_DIRS:-} ]]; then
    xdg_data_dirs=("${(@s/:/)XDG_DATA_DIRS}")
fi

typeset -a xdg_unique_data_dirs=()
typeset xdg_dir xdg_existing
typeset -i xdg_seen
for xdg_dir in "${xdg_data_dirs[@]}"; do
    [[ -n "$xdg_dir" ]] || continue
    xdg_seen=0
    for xdg_existing in "${xdg_unique_data_dirs[@]}"; do
        [[ "$xdg_existing" == "$xdg_dir" ]] && xdg_seen=1 && break
    done
    (( xdg_seen )) || xdg_unique_data_dirs+=("$xdg_dir")
done
xdg_seen=0
for xdg_existing in "${xdg_unique_data_dirs[@]}"; do
    [[ "$xdg_existing" == "$XDG_DATA_HOME" ]] && xdg_seen=1 && break
done
(( xdg_seen )) || xdg_unique_data_dirs=("$XDG_DATA_HOME" "${xdg_unique_data_dirs[@]}")
export XDG_DATA_DIRS="${(j.:.)xdg_unique_data_dirs}"
unset xdg_data_dirs xdg_unique_data_dirs xdg_dir xdg_existing xdg_seen

# Home Manager's configured values are the fallback; xdg-user-dir wins when available.
# @XDG_USER_DIR_ASSIGNMENTS@
if (( $+commands[xdg-user-dir] )); then
    for xdg_user_dir_name in DESKTOP DOCUMENTS DOWNLOAD MUSIC PICTURES PUBLICSHARE TEMPLATES VIDEOS; do
        xdg_user_dir_value="$(xdg-user-dir "$xdg_user_dir_name")"
        [[ -n "$xdg_user_dir_value" ]] && export "XDG_${xdg_user_dir_name}_DIR=$xdg_user_dir_value"
    done
fi
unset xdg_user_dir_name xdg_user_dir_value
