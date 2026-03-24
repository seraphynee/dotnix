{
  __findFile,
  lib,
  ...
}:
{
  den.aspects.shell._.opencode =
    { user, ... }:
    {
      nixos =
        { pkgs, ... }:
        {
          environment.systemPackages = with pkgs; [ opencode ];
        };

      homeManager =
        { config, ... }:
        {
          sops.templates."opencode-config.json" = {
            path = "${config.home.homeDirectory}/.config/opencode/opencode.json";
            mode = "0600";
            content = builtins.toJSON {
              "$schema" = "https://opencode.ai/config.json";
              mcp = {
                "Ref" = {
                  type = "remote";
                  url = "https://api.ref.tools/mcp?apiKey=${config.sops.placeholder."llm/ref_apikey"}";
                  enabled = true;
                };
                deepwiki = {
                  type = "remote";
                  url = "https://mcp.deepwiki.com/mcp";
                  headers = { };
                  enabled = true;
                };
                gitmcp = {
                  type = "remote";
                  url = "https://gitmcp.io/chianyungcode/dotfiles";
                  headers = { };
                  enabled = false;
                };
                exa = {
                  type = "remote";
                  url = "https://mcp.exa.ai/mcp";
                  headers = { };
                  enabled = true;
                };
                context7 = {
                  type = "remote";
                  url = "https://mcp.context7.com/mcp";
                  headers = {
                    CONTEXT7_API_KEY = config.sops.placeholder."llm/context7_apikey";
                  };
                  enabled = true;
                };
                grep = {
                  type = "remote";
                  url = "https://mcp.grep.app";
                  enabled = false;
                };
                linear = {
                  type = "local";
                  command = [
                    "bun"
                    "x"
                    "mcp-remote"
                    "https://mcp.linear.app/mcp"
                  ];
                  enabled = true;
                };
                tavily = {
                  type = "remote";
                  url = "https://mcp.tavily.com/mcp/?tavilyApiKey=${config.sops.placeholder."llm/tavily_apikey"}";
                  enabled = true;
                };
              };
            };
          };
        };
    };
}
