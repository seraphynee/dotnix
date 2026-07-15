{ __findFile, inputs, ... }:
let
  mkMcpServers = config: {
    Ref = {
      type = "remote";
      url = "https://api.ref.tools/mcp?apiKey=${config.sops.placeholder."llm/ref_apikey"}";
      enabled = false;
    };

    context7 = {
      type = "remote";
      url = "https://mcp.context7.com/mcp";
      enabled = true;
    };

    deepwiki = {
      type = "remote";
      url = "https://mcp.deepwiki.com/mcp";
      headers = { };
      enabled = false;
    };

    exa = {
      type = "remote";
      url = "https://mcp.exa.ai/mcp";
      headers = { };
      enabled = false;
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
      enabled = false;
    };

    ticktick = {
      type = "remote";
      url = "https://mcp.ticktick.com";
      enabled = true;
    };
  };

  mkCodexMcpServer =
    name: server:
    let
      enabled = if server ? enabled then server.enabled else true;
    in
    ''
      [mcp_servers.${name}]
      url = "${server.url}"
      enabled = ${if enabled then "true" else "false"}
    '';

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

  mkGrokMcpServer =
    name: server:
    let
      enabled = if server ? enabled then server.enabled else true;
      headers =
        if server ? headers && server.headers != { } then
          let
            headerEntries = builtins.attrValues (
              builtins.mapAttrs (k: v: ''"${k}" = "${v}"'') server.headers
            );
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

  # Global pi agent settings (~/.config/pi/settings.json via PI_CODING_AGENT_DIR).
  # Packages listed here are installed automatically on first use if missing.
  mkPiConfig = builtins.toJSON {
    theme = "dark";
    packages = [ "npm:pi-mcp-adapter" ];
  };

  # Cursor Agent CLI (~/.cursor/cli-config.json).
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

  # Cursor Agent CLI MCP (~/.cursor/mcp.json).
  # Cursor uses { mcpServers.<name> = { url, headers? } } — no enabled flag;
  # disable unused servers with `agent mcp disable <name>`.
  mkCursorMcpConfig =
    config:
    let
      servers = mkMcpServers config;
      toCursorServer =
        _name: server:
        { url = server.url; }
        // (
          if server ? headers && server.headers != { } then
            { headers = server.headers; }
          else
            { }
        );
    in
    builtins.toJSON {
      mcpServers = builtins.mapAttrs toCursorServer servers;
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
          grokConfig = mkGrokConfig config;
          piConfig = mkPiConfig;
          cursorCliConfig = mkCursorCliConfig;
          cursorMcpConfig = mkCursorMcpConfig config;
          octFishCommand = "env OPENCODE_CONFIG_DIR=$HOME/.config/opencode-thinking opencode";
          octZshCommand = "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-thinking opencode";
        in
        {
          sops.templates."codex-config.toml" = {
            path = "${config.home.homeDirectory}/.codex/config.toml";
            mode = "0600";
            content = codexConfig;
          };

          sops.templates."grok-config.toml" = {
            path = "${config.home.homeDirectory}/.grok/config.toml";
            mode = "0600";
            content = grokConfig;
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

          sops.templates."cursor-mcp.json" = {
            path = "${config.home.homeDirectory}/.cursor/mcp.json";
            mode = "0600";
            content = cursorMcpConfig;
          };

          home.file.".cursor/cli-config.json".text = cursorCliConfig;

          xdg.configFile."opencode-thinking" = {
            source = ../../dots/config/opencode-thinking;
            recursive = true;
          };

          # PI_CODING_AGENT_DIR relocates global agent config from ~/.pi/agent.
          home.sessionVariables.PI_CODING_AGENT_DIR = "${config.xdg.configHome}/pi";

          xdg.configFile."pi/settings.json".text = piConfig;

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
            llmPackages.cursor-agent
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
