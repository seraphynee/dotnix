{
  pkgs,
  ...
}:

{
  env.GREET = "devenv";

  packages = with pkgs; [
    git
    just
    lefthook
    nh
    gitleaks
  ];

  scripts = {
    rb = {
      exec = ''
        if [ "$(uname -s)" = "Darwin" ]; then nh darwin switch . -H $1; else nh os switch . -H $1; fi
      '';
      description = "Rebuild and switch to a host configuration";
    };
    rbb = {
      exec = ''
        nh os boot . -H $1
      '';
      description = "Build a NixOS configuration for the next boot";
    };
    up = {
      exec = ''
        nix flake update $1
      '';
      description = "Update a selected flake input";
    };
    upp = {
      exec = ''
        nix flake update
      '';
      description = "Update all flake inputs";
    };
    fmt-fix = {
      exec = ''
        nix fmt
      '';
      description = "Format repository files";
    };
    fmt-check = {
      exec = ''
        nix fmt -- --ci
      '';
      description = "Check repository formatting";
    };
    flake-check = {
      exec = ''
        nix flake check --print-build-logs
      '';
      description = "Evaluate and test the flake";
    };
    secrets-scan = {
      exec = ''
        gitleaks detect --source . --verbose
      '';
      description = "Scan the repository for leaked secrets";
    };
    ci-check = {
      exec = ''
        fmt-check && flake-check
      '';
      description = "Run formatting and flake checks";
    };
    write-flake = {
      exec = ''
        nix run .#write-flake
      '';
      description = "Regenerate the generated flake";
    };
  };

  tasks."repo:install-lefthook" = {
    exec = "just hooks-install";
    status = ''
      [ -f .git/hooks/pre-commit ] &&
      [ -f .git/hooks/pre-push ] &&
      grep -q lefthook .git/hooks/pre-commit &&
      grep -q lefthook .git/hooks/pre-push
    '';
    before = [ "devenv:enterShell" ];
  };

  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

}
