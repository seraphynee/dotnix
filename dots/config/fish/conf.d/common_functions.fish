function path
    string split : $PATH
end

function fpath
    string split : $FPATH
end

function whichcli
    # whichcli: show the active CLI binary and other installed locations.
    if test (count $argv) -eq 0
        echo "Usage: whichcli <command>"
        return 1
    end

    set -l cli $argv[1]
    set -l active (command -v -- $cli 2>/dev/null)
    if test -z "$active"
        echo "Command '$cli' not found in PATH."
        return 1
    end

    set -l active_real $active
    if command -q realpath
        set active_real (realpath $active 2>/dev/null; or echo $active)
    end

    echo "Command        : $cli"
    echo "Active binary  : $active"
    if test "$active_real" != "$active"
        echo "Resolved active: $active_real"
    end

    set -l candidates
    for d in $PATH
        if test -n "$d"; and test -x "$d/$cli"
            set -a candidates "$d/$cli"
        end
    end

    set -l brew_prefix ""
    set -l brew_cli_prefix ""
    if command -q brew
        set brew_prefix (brew --prefix 2>/dev/null)
        if test -n "$brew_prefix"; and test -x "$brew_prefix/bin/$cli"
            set -a candidates "$brew_prefix/bin/$cli"
        end
        if test -n "$brew_prefix"; and test -x "$brew_prefix/sbin/$cli"
            set -a candidates "$brew_prefix/sbin/$cli"
        end

        set brew_cli_prefix (brew --prefix $cli 2>/dev/null)
        if test -n "$brew_cli_prefix"; and test -x "$brew_cli_prefix/bin/$cli"
            set -a candidates "$brew_cli_prefix/bin/$cli"
        end
    end

    set -l npm_prefix ""
    if command -q npm
        set npm_prefix (npm prefix -g 2>/dev/null)
        if test -n "$npm_prefix"; and test -x "$npm_prefix/bin/$cli"
            set -a candidates "$npm_prefix/bin/$cli"
        end
    end

    set -l seen
    set -l others
    for p in $candidates
        set -l rp $p
        if command -q realpath
            set rp (realpath $p 2>/dev/null; or echo $p)
        end

        contains -- $rp $seen; and continue
        set -a seen $rp

        if test "$rp" != "$active_real"
            set -a others $p
        end
    end

    if test (count $others) -eq 0
        echo "Other installs : none detected"
        return 0
    end

    echo "Other installs :"
    for p in $others
        set -l source_label PATH
        if string match -qr -- '/Cellar/|^/opt/homebrew/|^/usr/local/' $p
            set source_label "Homebrew?"
        end
        if test -n "$npm_prefix"; and string match -q -- "$npm_prefix/bin/*" $p
            set source_label "npm -g"
        end
        echo "  - [$source_label] $p"
    end
end

function mcd
    mkdir -pv $argv[1]
    cd $argv[1]
end
