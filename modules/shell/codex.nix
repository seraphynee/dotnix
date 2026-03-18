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
        { config, pkgs, ... }:
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

          codexConfig =
            builtins.replaceStrings
              [
                "@conditional_trusted_projects@"
                "@context7_api_key@"
                "@ref_api_key@"
                "@tavily_api_key@"
              ]
              [
                trustedProjects
                config.sops.placeholder."llm/context7_apikey"
                config.sops.placeholder."llm/ref_apikey"
                config.sops.placeholder."llm/tavily_apikey"
              ]
              (builtins.readFile ../../dots/dot_codex/config.toml.tmpl);
        in
        {
          sops.templates."codex-config.toml" = {
            path = "${config.home.homeDirectory}/.codex/config.toml";
            mode = "0600";
            content = codexConfig;
          };
        };

      nixos =
        { pkgs, ... }:
        let
          inherit (inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system}) codex;
        in
        {
          environment.systemPackages = [ codex ];
        };
    };
}
