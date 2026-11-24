{ mkMcpServers }:
let
  # OpenCode v2 schema: MCP servers live under `mcp.servers` and use
  # `disabled` instead of v1's `enabled`; provider options moved to `settings`.
  toOpencodeServer = _name: server: {
    inherit (server) type url headers;
    disabled = !(server.enabled or true);
  };

  mkOpencodeConfig =
    config:
    builtins.toJSON {
      model = "opencode-go/deepseek-v4.1-flash";
      mcp.servers = builtins.mapAttrs toOpencodeServer (mkMcpServers config);
      providers.openrouter = {
        models."z-ai/glm-5".settings.provider = {
          order = [
            "baseten"
            "z.ai"
          ];
          allow_fallbacks = false;
        };
        settings.apiKey = "{env:OPENROUTER_API_KEY}";
      };
    };
in
{
  inherit mkOpencodeConfig;
}
