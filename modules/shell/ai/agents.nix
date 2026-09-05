{ inputs, paths, ... }:
let
  mkMcpServers = import (paths.root + "/lib/shell/ai/mcp.nix");
  inherit (import (paths.root + "/lib/shell/ai/codex.nix") { inherit mkMcpServers; }) mkCodexConfig;
  inherit (import (paths.root + "/lib/shell/ai/grok.nix") { inherit mkMcpServers; }) mkGrokConfig;
  inherit (import (paths.root + "/lib/shell/ai/opencode.nix") { inherit mkMcpServers; })
    mkOpencodeConfig
    ;
  inherit (import (paths.root + "/lib/shell/ai/pi.nix") { inherit mkMcpServers; })
    mkPiConfig
    mkPiMcpConfig
    ;
  inherit (import (paths.root + "/lib/shell/ai/cursor.nix") { inherit mkMcpServers; })
    mkCursorCliConfig
    mkCursorMcpConfig
    ;
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
            source = paths.dots + "/config/opencode-thinking";
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
