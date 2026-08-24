{ __findFile, inputs, ... }:
let
  mkMcpServers = config: {
    context7 = {
      type = "remote";
      url = "https://mcp.context7.com/mcp";
      headers = {
        Authorization = "Bearer ${config.sops.placeholder."llm/context7_apikey"}";
      };
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
      headers = {
        Authorization = "Bearer ${config.sops.placeholder."llm/exa_apikey"}";
      };
      enabled = true;
    };

    capacities = {
      type = "remote";
      url = "https://api.capacities.io/mcp";
      headers = { };
      enabled = true;
    };

    linear = {
      type = "remote";
      url = "https://mcp.linear.app/mcp";
      headers = {
        Authorization = "Bearer ${config.sops.placeholder."llm/linear_apikey"}";
      };
      enabled = true;
    };

    tavily = {
      type = "remote";
      url = "https://mcp.tavily.com/mcp";
      headers = {
        Authorization = "Bearer ${config.sops.placeholder."llm/tavily_apikey"}";
      };
      enabled = false;
    };

    ticktick = {
      type = "remote";
      url = "https://mcp.ticktick.com";
      headers = {
        Authorization = "Bearer ${config.sops.placeholder."llm/ticktick_apikey"}";
      };
      enabled = true;
    };
  };

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
      model = "gpt-5.6-sol"
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

  # Global pi agent settings (~/.config/pi/settings.json via PI_CODING_AGENT_DIR).
  # Packages listed here are installed automatically on first use if missing.
  mkPiConfig = builtins.toJSON {
    theme = "dark";
    defaultThinkingLevel = "high";
    defaultProvider = "openrouter";
    defaultModel = "stealth/ox-alpha";
    enabledModels = [
      "openrouter/stealth/ox-alpha"
      "openai-codex/gpt-5.6-luna"
      "openai-codex/gpt-5.6-sol"
      "openai-codex/gpt-5.6-terra"
    ];

    packages = [
      {
        source = "npm:pi-caveman";
        autoload = false;
      }
      {
        source = "npm:pi-context-view";
        autoload = true;
      }
      {
        source = "npm:pi-markdown-preview";
        autoload = true;
      }
      {
        source = "npm:pi-mcp-adapter";
        autoload = true;
      }
      {
        source = "npm:pi-skill-gate";
        autoload = false;
      }
      {
        source = "npm:pi-subagents";
        autoload = true;
      }
      {
        source = "npm:pi-web-access";
        autoload = true;
      }
      {
        source = "npm:@ff-labs/pi-fff";
        autoload = true;
      }
      {
        source = "npm:@dietrichgebert/ponytail";
        autoload = false;
      }
      {
        source = "npm:@narumitw/pi-btw";
        autoload = true;
      }
      {
        source = "npm:@narumitw/pi-goal";
        autoload = false;
      }
      {
        source = "npm:@pi9/ask";
        autoload = true;
      }
      {
        source = "npm:@juicesharp/rpiv-todo";
        autoload = false;
      }
    ];
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

  # Pi coding agent MCP ($PI_CODING_AGENT_DIR/mcp.json → ~/.config/pi/mcp.json).
  # Same { mcpServers.<name> = { url, headers? } } shape as Cursor; the enabled
  # flag becomes { disabled = true; }.
  mkPiMcpConfig =
    config:
    let
      servers = mkMcpServers config;
      toPiServer =
        _name: server:
        {
          inherit (server) url;
        }
        // (if server ? headers && server.headers != { } then { inherit (server) headers; } else { })
        // (if server.enabled or true then { } else { disabled = true; });
    in
    builtins.toJSON {
      mcpServers = builtins.mapAttrs toPiServer servers;
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
  # Shared agent instructions
  den.aspects.shell._.ai = {
    homeManager = {
      home.file.".agents" = {
        source = ../../dots/agents;
      };
    };
  };
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
          piMcpConfig = mkPiMcpConfig config;
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

          sops.templates."pi-mcp.json" = {
            path = "${config.home.homeDirectory}/.config/pi/mcp.json";
            mode = "0600";
            content = piMcpConfig;
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
