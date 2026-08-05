if type -q jj
function __jj_workspace_cd
    set -l destination (command jj $argv)
    or return
    if not test -d "$destination"
        echo "jj: workspace directory does not exist: $destination" >&2
        return 1
    end
    builtin cd -- "$destination"
end

function wq
    __jj_workspace_cd wq $argv
end

function wcd
    __jj_workspace_cd wcd $argv
end

function wacd
    __jj_workspace_cd wacd $argv
end

# Jujutsu aliases run in a child process, so apply workspace paths here.
function jj --description 'Jujutsu wrapper with workspace navigation'
    set -l subcommand ''
    if test (count $argv) -gt 0
        set subcommand $argv[1]
    end

    switch "$subcommand"
        case wq wcd wacd
            $subcommand $argv[2..-1]
        case '*'
            command jj $argv
    end
end
end
