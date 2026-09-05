{ mkMcpServers }:
let
  mkGrokMcpServer =
    name: server:
    let
      enabled = server.enabled or true;
      headers =
        if server ? headers && server.headers != { } then
          let
            headerEntries = builtins.attrValues (builtins.mapAttrs (k: v: ''"${k}" = "${v}"'') server.headers);
          in
          ''
            headers = { ${builtins.concatStringsSep ", " headerEntries} }
          ''
        else
          "";
    in
    ''
      [mcp_servers.${name}]
      url = "${server.url}"
      enabled = ${if enabled then "true" else "false"}
    ''
    + headers;

  mkGrokConfig =
    config:
    let
      servers = mkMcpServers config;
    in
    ''
      [cli]
      installer = "internal"

      [ui]
      compact_mode         = false
      fork_secondary_model = "grok-build"
      max_thoughts_width   = 120
      permission_mode      = "always-approve"
      yolo                 = false

      [marketplace]
      official_marketplace_auto_installed = true

      [[marketplace.sources]]
        git  = "https://github.com/xai-org/plugin-marketplace.git"
        name = "xAI Official"

      [telemetry]
      trace_upload = false

      [harness]
      disable_codebase_upload = true

      ${builtins.concatStringsSep "\n" (
        map (name: mkGrokMcpServer name servers.${name}) (builtins.attrNames servers)
      )}
    '';

in
{
  inherit mkGrokConfig;
}
