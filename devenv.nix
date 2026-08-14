{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  env.GREET = "devenv";

  packages = with pkgs; [
    git
    just
    lefthook
  ];

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
