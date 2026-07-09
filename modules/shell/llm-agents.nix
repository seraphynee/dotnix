{ __findFile, inputs, ... }:
let
  mkMcpServers = config: {
    Ref = {
      type = "remote";
      url = "https://api.ref.tools/mcp?apiKey=${config.sops.placeholder."llm/ref_apikey"}";
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

    deepwiki = {
      type = "remote";
      url = "https://mcp.deepwiki.com/mcp";
      headers = { };
      enabled = true;
    };

    exa = {
      type = "remote";
      url = "https://mcp.exa.ai/mcp";
      headers = { };
      enabled = true;
    };

    gitmcp = {
      type = "remote";
      url = "https://gitmcp.io/chianyungcode/dotfiles";
      headers = { };
      enabled = false;
    };

    grep = {
      type = "remote";
      url = "https://mcp.grep.app";
      enabled = false;
    };

    linear = {
      type = "remote";
      url = "https://mcp.linear.app/mcp";
      enabled = true;
    };

    tavily = {
      type = "remote";
      url = "https://mcp.tavily.com/mcp/?tavilyApiKey=${config.sops.placeholder."llm/tavily_apikey"}";
      enabled = true;
    };

    ticktick = {
      type = "remote";
      url = "https://mcp.ticktick.com";
      enabled = true;
    };
  };

  mkCodexMcpServer =
    name: server:
    ''
      [mcp_servers.${name}]
      url = "${server.url}"
    ''
    + (
      if server ? enabled && !server.enabled then
        ''
          enabled = false
        ''
      else
        ""
    )
    + (
      if name == "context7" then
        ''
          http_headers = { "CONTEXT7_API_KEY" = "${server.headers.CONTEXT7_API_KEY}" }
        ''
      else
        ""
    );

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
            [projects."/home/${username}/dotnix"]
            trust_level = "trusted"

            [projects."/home/${username}/Code/Personal/dotfiles"]
            trust_level = "trusted"
          ''
        else
          "";
    in
    ''
      model = "gpt-5.6-sol"
      model_reasoning_effort = "xhigh"

      [features]
      ${builtins.concatStringsSep "\n" (
        map (name: mkCodexMcpServer name servers.${name}) (builtins.attrNames servers)
      )}

      ${trustedProjects}
    '';

  mkOpencodeConfig =
    config:
    builtins.toJSON {
      "$schema" = "https://opencode.ai/config.json";
      plugin = [ "superpowers@git+https://github.com/obra/superpowers.git" ];
      mcp = mkMcpServers config;
    };
in
{
  den.aspects.shell._.llm_agents =
    { user, ... }:
    {
      homeManager =
        { config, pkgs, ... }:
        let
          inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;

          codexConfig = mkCodexConfig {
            inherit config isDarwin isLinux;
            username = user.userName;
          };

          opencodeConfig = mkOpencodeConfig config;
          octFishCommand = "env OPENCODE_CONFIG_DIR=$HOME/.config/opencode-thinking opencode";
          octZshCommand = "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-thinking opencode";
        in
        {
          sops.templates."codex-config.toml" = {
            path = "${config.home.homeDirectory}/.codex/config.toml";
            mode = "0600";
            content = codexConfig;
          };

          sops.templates."opencode-config.json" = {
            path = "${config.home.homeDirectory}/.config/opencode/opencode.json";
            mode = "0600";
            content = opencodeConfig;
          };

          sops.templates."opencode-thinking-config.json" = {
            path = "${config.home.homeDirectory}/.config/opencode-thinking/opencode.json";
            mode = "0600";
            content = opencodeConfig;
          };

          xdg.configFile."opencode-thinking" = {
            source = ../../dots/config/opencode-thinking;
            recursive = true;
          };

          programs = {
            fish.shellAliases = {
              oct = octFishCommand;
            };

            zsh.shellAliases = {
              oct = octZshCommand;
            };
          };
        };

      nixos =
        { pkgs, ... }:
        let
          llmPackages = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
        in
        {
          environment.systemPackages = [
            llmPackages.codex
            llmPackages.grok
            llmPackages.opencode
            llmPackages.pi
            pkgs.bubblewrap
          ];

          # Codex currently probes for a system bubblewrap at /usr/bin/bwrap.
          # NixOS exposes it in the system profile instead, so provide the path
          # Codex expects to avoid the vendored bubblewrap fallback warning.
          systemd.tmpfiles.rules = [
            "L+ /usr/bin/bwrap - - - - ${pkgs.bubblewrap}/bin/bwrap"
          ];
        };
    };
}
