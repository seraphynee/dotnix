{ paths, ... }:
{
  den.aspects.shell._.formatters.homeManager =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        rustfmt
      ];

      xdg.configFile = {
        "biome/biome.jsonc".source = paths.dots + "/config/biome/biome.jsonc.tmpl";
        "stylua/stylua.toml".source = paths.dots + "/config/stylua/stylua.toml.tmpl";
        "yamlfmt/yamlfmt.yaml".source = paths.dots + "/config/yamlfmt/yamlfmt.yaml.tmpl";
        "taplo/taplo.yaml".source = paths.dots + "/config/taplo/taplo.toml.tmpl";
        "rustfmt/rustfmt.toml".source = paths.dots + "/config/rustfmt/rustfmt.toml.tmpl";
        "rumdl/rumdl.toml".source = paths.dots + "/config/rumdl/rumdl.toml.tmpl";
        "shellcheckrc".source = paths.dots + "/config/shellcheckrc.tmpl";
        "typos/config.toml".source = paths.dots + "/config/typos/config.toml.tmpl";
      };
    };
}
