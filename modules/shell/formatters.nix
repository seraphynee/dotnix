_: {
  den.aspects.shell._.formatters.homeManager =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        rustfmt
      ];

      xdg.configFile = {
        "biome/biome.jsonc".source = ../../dots/config/biome/biome.jsonc.tmpl;
        "stylua/stylua.toml".source = ../../dots/config/stylua/stylua.toml.tmpl;
        "yamlfmt/yamlfmt.yaml".source = ../../dots/config/yamlfmt/yamlfmt.yaml.tmpl;
        "taplo/taplo.yaml".source = ../../dots/config/taplo/taplo.toml.tmpl;
        "rustfmt/rustfmt.toml".source = ../../dots/config/rustfmt/rustfmt.toml.tmpl;
        "rumdl/rumdl.toml".source = ../../dots/config/rumdl/rumdl.toml.tmpl;
        "shellcheckrc".source = ../../dots/config/shellcheckrc.tmpl;
        "typos/config.toml".source = ../../dots/config/typos/config.toml.tmpl;
      };
    };
}
