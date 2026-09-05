{ mkMcpServers }:
let
  mkOpencodeConfig =
    config:
    builtins.toJSON {
      "$schema" = "https://opencode.ai/config.json";
      theme = "opencode";
      # plugin = [ "superpowers@git+https://github.com/obra/superpowers.git" ];
      mcp = mkMcpServers config;
      provider = {
        openrouter = {
          models = {
            "z-ai/glm-5.2" = {
              options.provider = {
                order = [
                  "fireworks"
                  "z.ai"
                ];
                allow_fallbacks = false;
              };
            };
          };
          options.apiKey = "{env:OPENROUTER_API_KEY}";
        };
      };
    };
in
{
  inherit mkOpencodeConfig;
}
