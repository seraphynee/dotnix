set -gx XDG_DATA_HOME @XDG_DATA_HOME@
set -gx XDG_CONFIG_HOME @XDG_CONFIG_HOME@
set -gx XDG_STATE_HOME @XDG_STATE_HOME@
set -gx XDG_CACHE_HOME @XDG_CACHE_HOME@

set -l xdg_data_dirs
if set -q XDG_DATA_DIRS
    set xdg_data_dirs (string split : -- "$XDG_DATA_DIRS")
end

set -l xdg_unique_data_dirs
for xdg_dir in $xdg_data_dirs
    if test -n "$xdg_dir"; and not contains -- "$xdg_dir" $xdg_unique_data_dirs
        set -a xdg_unique_data_dirs "$xdg_dir"
    end
end
if not contains -- "$XDG_DATA_HOME" $xdg_unique_data_dirs
    set -p xdg_unique_data_dirs "$XDG_DATA_HOME"
end
set -gx XDG_DATA_DIRS (string join : $xdg_unique_data_dirs)

# Home Manager's configured values are the fallback; xdg-user-dir wins when available.
# @XDG_USER_DIR_ASSIGNMENTS@
if type -q xdg-user-dir
# @XDG_USER_DIR_EXPORTS@
end
