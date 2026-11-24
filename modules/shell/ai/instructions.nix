{ inputs, paths, ... }:
{
  den.aspects.shell._.ai = {
    homeManager =
      { config, ... }:
      let
        agentsMd = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.agents/AGENTS.md";
      in
      {
        home.file = {
          # Recursive so public skills (and future sops-managed files) can live
          # next to the files from dots/agents.
          ".agents" = {
            source = paths.dots + "/agents";
            recursive = true;
          };
          ".agents/skills/caveman".source = inputs.caveman + "/skills/caveman";
          ".agents/skills/ponytail".source = inputs.ponytail + "/skills/ponytail";

          # Codex and Claude Code read the shared global instructions.
          ".codex/AGENTS.md".source = agentsMd;
          ".claude/CLAUDE.md".source = agentsMd;
          ".claude/settings.json".text = builtins.toJSON {
            "$schema" = "https://json.schemastore.org/claude-code-settings.json";
            model = "claude-sonnet-5-5";
            effortLevel = "high";
          };
        };
      };
  };
}
