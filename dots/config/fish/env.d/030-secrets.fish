# sops-nix writes these files during activation. Keep this bridge silent when
# an optional secret is not configured or is not available on this host.
set -l sops_secret_dir "$XDG_CONFIG_HOME/sops-nix/secrets"

set -l context7_secret "$sops_secret_dir/llm/context7_apikey"
if test -r "$context7_secret"
    set -gx CONTEXT7_MCP_API_KEY (command cat -- "$context7_secret")
end

if set -q GITHUB_TOKEN_FILE; and test -r "$GITHUB_TOKEN_FILE"
    set -gx GITHUB_TOKEN (command cat -- "$GITHUB_TOKEN_FILE")
else
    set -l github_secret "$sops_secret_dir/keys/pat/ghspy-pat"
    if test -r "$github_secret"
        set -gx GITHUB_TOKEN (command cat -- "$github_secret")
    end
end

set -l openrouter_secret "$sops_secret_dir/llm/openrouter_apikey"
if test -r "$openrouter_secret"
    set -gx OPENROUTER_API_KEY (command cat -- "$openrouter_secret")
end

set -l wakatime_secret "$sops_secret_dir/productivity/wakatime_apikey"
if test -r "$wakatime_secret"
    set -gx WAKATIME_API_KEY (command cat -- "$wakatime_secret")
end
