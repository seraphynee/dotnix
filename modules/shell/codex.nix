{
  __findFile,
  inputs,
  constants,
  ...
}:
{
  den.aspects.shell._.codex = {
    homeManager =
      { pkgs, ... }:
      let
        inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;

        trustedProjects =
          if isDarwin then
            ''
              [projects."/Users/${constants.user_one}/.local/share/chezmoi"]
              trust_level = "trusted"

              [projects."/Users/${constants.user_one}/Code/Personal/Projects/Backend/allweezy-backend"]
              trust_level = "trusted"
            ''
          else if isLinux then
            ''
              [projects."/home/${constants.user_two}/dotnix"]
              trust_level = "trusted"
            ''
          else
            "";

        codexConfig = builtins.replaceStrings [ "@conditional_trusted_projects@" ] [ trustedProjects ] (
          builtins.readFile ../../dots/dot_codex/config.toml.tmpl
        );
      in
      {
        home.file.".codex/config.toml".text = codexConfig;
      };

    nixos =
      { pkgs, ... }:
      let
        inherit (inputs.nixpkgs-master.legacyPackages.${pkgs.system}) codex;
      in
      {
        environment.systemPackages = [ codex ];
      };
  };
}
