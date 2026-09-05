{ mkMcpServers }:
let
  mkCodexMcpServer =
    name: server:
    let
      enabled = server.enabled or true;
      httpHeaders =
        if server ? headers && server.headers != { } then
          let
            headerEntries = builtins.attrValues (builtins.mapAttrs (k: v: ''"${k}" = "${v}"'') server.headers);
          in
          ''
            http_headers = { ${builtins.concatStringsSep ", " headerEntries} }
          ''
        else
          "";
    in
    ''
      [mcp_servers.${name}]
      url = "${server.url}"
      enabled = ${if enabled then "true" else "false"}
    ''
    + httpHeaders;

  mkCodexConfig =
    {
      config,
      isDarwin,
      isLinux,
      username,
    }:
    let
      servers = mkMcpServers config;
      trustedProjects =
        if isDarwin then
          ''
            [projects."/Users/${username}/.local/share/chezmoi"]
            trust_level = "trusted"

            [projects."/Users/${username}/Code/Personal/Projects/Backend/allweezy-backend"]
            trust_level = "trusted"
          ''
        else if isLinux then
          ''
            [projects."/home/${username}/Code/Personal/Projects/dotnix"]
            trust_level = "trusted"

            [projects."/home/${username}/Code/Personal/Projects/dotfiles"]
            trust_level = "trusted"
          ''
        else
          "";
    in
    ''
      model = "gpt-5.6-luna"
      model_reasoning_effort = "high"

      [features]
      ${builtins.concatStringsSep "\n" (
        map (name: mkCodexMcpServer name servers.${name}) (builtins.attrNames servers)
      )}

      ${trustedProjects}

      [tui]
      status_line = ["model-with-reasoning", "current-dir", "context-used", "weekly-limit"]
      status_line_use_colors = true
    '';
in
{
  inherit mkCodexConfig;
}
