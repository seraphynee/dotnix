{
  __findFile,
  inputs,
  ...
}:
{
  den.aspects.shell._.codex =
    { user, ... }:
    {
      homeManager =
        { pkgs, ... }:
        let
          inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
          username = user.userName;

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
