if type -q herdr
    set -l herdr_hooks (command find "$XDG_CONFIG_HOME/herdr/plugins/github" -type f -path '*/herdr-automatic-rename-*/shell/hook.fish' -print 2>/dev/null)
    for _f in $herdr_hooks
        if test -r "$_f"
            source "$_f"
            break
        end
    end
end
