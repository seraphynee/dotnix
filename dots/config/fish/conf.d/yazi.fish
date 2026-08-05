function y
    type -q yazi; or return 127
    set -l tmp (mktemp -t yazi-cwd.XXXXXX)
    or return 1

    yazi $argv --cwd-file=$tmp
    set -l yazi_status $status
    if test $yazi_status -eq 0; and test -r "$tmp"
        set -l cwd (command cat -- "$tmp")
        if test -n "$cwd"; and test "$cwd" != "$PWD"; and test -d "$cwd"
            builtin cd -- "$cwd"
        end
    end
    command rm -f -- "$tmp"
    return $yazi_status
end
