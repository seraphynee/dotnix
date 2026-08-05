# sops-nix writes these files during activation. Keep this bridge silent when
# an optional secret is not configured or is not available on this host.
typeset sops_secret_dir="${XDG_CONFIG_HOME}/sops-nix/secrets"

typeset context7_secret="$sops_secret_dir/llm/context7_apikey"
if [[ -r "$context7_secret" ]]; then
    export CONTEXT7_MCP_API_KEY="$(< "$context7_secret")"
fi

if [[ -n ${GITHUB_TOKEN_FILE:-} && -r "$GITHUB_TOKEN_FILE" ]]; then
    export GITHUB_TOKEN="$(< "$GITHUB_TOKEN_FILE")"
else
    typeset github_secret="$sops_secret_dir/keys/pat/ghspy-pat"
    if [[ -r "$github_secret" ]]; then
        export GITHUB_TOKEN="$(< "$github_secret")"
    fi
fi

typeset openrouter_secret="$sops_secret_dir/llm/openrouter_apikey"
if [[ -r "$openrouter_secret" ]]; then
    export OPENROUTER_API_KEY="$(< "$openrouter_secret")"
fi

typeset wakatime_secret="$sops_secret_dir/productivity/wakatime_apikey"
if [[ -r "$wakatime_secret" ]]; then
    export WAKATIME_API_KEY="$(< "$wakatime_secret")"
fi

unset sops_secret_dir context7_secret github_secret openrouter_secret wakatime_secret
