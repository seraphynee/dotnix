if type -q chezmoi; and type -q nvim
    function nvdot
        command nvim "$XDG_DATA_HOME/chezmoi" $argv
    end
end
