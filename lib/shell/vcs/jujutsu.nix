{
  config,
  lib,
  pkgs,
  ...
}:
let
  mkJujutsuProfile =
    {
      gitUser,
      gitEmail,
      signingKeySecret ? null,
      workstation ? false,
      bookmarkPrefix,
    }:
    { config, ... }:
    let
      signingKeyPath =
        if signingKeySecret == null then
          null
        else
          lib.attrByPath [
            "sops"
            "secrets"
            signingKeySecret
            "path"
          ] null config;
    in
    {
      programs.jujutsu = {
        enable = true;
        settings = {
          user = {
            name = gitUser;
            email = gitEmail;
          };

          ui = {
            "default-command" = [
              "log"
              "-r"
              "@"
              "--no-graph"
              "-p"
              "-s"
            ];
            "diff-editor" = "gitpatch";
            "merge-editor" = "diffconflicts";
            editor = "nvim";
          }
          // lib.optionalAttrs workstation {
            "diff-formatter" = [
              "difft"
              "--color=always"
              "$left"
              "$right"
            ];
          };

          "merge-tools".gitpatch = {
            program = "sh";
            "edit-args" = [
              "-c"
              ''
                set -eu
                rm -f "$right/JJ-INSTRUCTIONS"
                git -C "$left" init -q
                git -C "$left" add -A
                git -C "$left" commit -q -m baseline --allow-empty
                mv "$left/.git" "$right"
                git -C "$right" add --intent-to-add --ignore-removal .
                git -C "$right" add -p
                git -C "$right" diff-index --quiet --cached HEAD && { echo "No changes done, aborting split."; exit 1; }
                git -C "$right" commit -q -m split
                git -C "$right" reset -q --hard
              ''
            ];
          };

          "merge-tools".diffconflicts = {
            program = "nvim";
            "merge-args" = [
              "-c"
              "let g:jj_diffconflicts_marker_length=$marker_length"
              "-c"
              "JJDiffConflicts!"
              "$output"
              "$base"
              "$left"
              "$right"
            ];
            "merge-tool-edits-conflict-markers" = true;
          };

          remotes.origin."auto-track-bookmarks" = "glob:*";

          signing =
            if signingKeyPath != null then
              {
                behavior = "own";
                backend = "ssh";
                key = signingKeyPath;
              }
            else
              {
                behavior = "drop";
                backend = "none";
              };

          templates.git_push_bookmark = "\"${bookmarkPrefix}/push-\" ++ change_id.short()";

          "template-aliases" = {
            commit_change_ids = ''
              concat(
                format_field("Change ID", change_id.short(8)),
                format_field("Commit ID", commit_id.short(7)),
              )
            '';
            oneline_log = "separate(\" \", change_id.shortest(8), description.first_line(), commit_id.shortest(7))";
          };

          aliases = jujutsuAliases;

          snapshot."auto-update-stale" = true;

          lazyjj = {
            "layout-percent" = 30;
          }
          // lib.optionalAttrs workstation {
            "diff-tool" = "difft";
          };
        };
      };
    };
  jujutsuAliases = import ./jujutsu-aliases.nix;
  cfg = config.dotnix.vcs;
  bookmarkPrefix =
    if cfg.jujutsu.bookmarkPrefix != null then
      cfg.jujutsu.bookmarkPrefix
    else if cfg.github.username != null then
      cfg.github.username
    else
      cfg.identity.name;
  workstation = cfg.jujutsu.workstation;
  jujutsuProfile = {
    gitUser = cfg.identity.name;
    gitEmail = cfg.identity.email;
    signingKeySecret = cfg.signing.keySecret;
    inherit workstation;
    inherit bookmarkPrefix;
  };
in
{
  config = lib.mkIf cfg.jujutsu.enable (
    lib.mkMerge [
      ((mkJujutsuProfile jujutsuProfile) { inherit config; })
      {
        home.packages = with pkgs; [
          koji
          lazyjj
        ];

        programs = {
          jjui = {
            enable = true;
            settings = {
              preview = {
                position = "bottom";
                show_at_start = true;
              };

              ui = {
                # theme = "onedark-dark";
                tracer = {
                  enabled = true;
                };
              };

              leader = {
                bn = {
                  help = "Set new bookmark";
                  send = [
                    "$"
                    ''jj bookmark set -r "$change_id" $(gum input --placeholder "Name of the new bookmark")''
                    "enter"
                  ];
                };
              };
            };
          };
        };
      }
    ]
  );
}
