{
  lib,
  inputs,
  paths,
  ...
}:
let
  inherit (import (paths.root + "/lib/secrets/sops/builders.nix") { inherit lib inputs paths; })
    mkHomeManagerSops
    sharedSopsFile
    ;
in
{
  den.aspects.secrets._.sops = {
    homeManager = mkHomeManagerSops {
      defaultSopsFile = sharedSopsFile;
      secrets = {
        "espanso/email.yaml" = { };
        "llm/context7_apikey" = {
          key = "keys/api/context7";
        };
        "llm/openrouter_apikey" = {
          key = "keys/api/openrouter";
        };
        "productivity/wakatime_apikey" = {
          key = "keys/api/wakatime";
          mode = "0600";
        };
        "llm/ticktick_apikey" = {
          key = "keys/api/ticktick";
        };
        "llm/exa_apikey" = {
          key = "keys/api/exa";
        };
        "llm/linear_apikey" = {
          key = "keys/api/linear";
        };
        "llm/tavily_apikey" = {
          key = "keys/api/tavily";
        };
        "llm/oco_api_url" = {
          key = "keys/api/oco_url";
        };
        "llm/oco_api_key" = {
          key = "keys/api/oco_key";
        };
      };
      extraConfig.home.sessionVariables = {
        SOPS_AGE_KEY_FILE = "$HOME/.local/share/ages/keys.txt";
      };
    };

  };
}
