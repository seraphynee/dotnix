for _f in $XDG_CONFIG_HOME/herdr/plugins/github/herdr-automatic-rename-*/shell/hook.fish
    if test -r "$_f"
        source "$_f"
        break
    end
end
