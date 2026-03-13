#  █████╗ ██╗     ██╗ █████╗ ███████╗
# ██╔══██╗██║     ██║██╔══██╗██╔════╝
# ███████║██║     ██║███████║███████╗
# ██╔══██║██║     ██║██╔══██║╚════██║
# ██║  ██║███████╗██║██║  ██║███████║
# ╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═╝╚══════╝
# A simple wrapper for the function builtin, which creates a function wrapping a command
# https://fishshell.com/docs/current/cmds/alias.html

@common_aliases@

if command -sq gping
    alias ping gping
else if command -sq prettyping
    alias ping "prettyping --nolegend"
end
