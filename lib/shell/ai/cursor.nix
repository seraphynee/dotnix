{ mkMcpServers }:
let
  mkCursorCliConfig = builtins.toJSON {
    version = 1;
    editor = {
      vimMode = false;
    };
    permissions = {
      allow = [ ];
      deny = [ ];
    };
  };

  mkCursorMcpConfig =
    config:
    let
      servers = mkMcpServers config;
      toCursorServer =
        _name: server:
        {
          inherit (server) url;
        }
        // (if server ? headers && server.headers != { } then { inherit (server) headers; } else { });
    in
    builtins.toJSON {
      mcpServers = builtins.mapAttrs toCursorServer servers;
    };
in
{
  inherit mkCursorCliConfig mkCursorMcpConfig;
}
