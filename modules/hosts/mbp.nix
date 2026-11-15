{
  __findFile,
  constants,
  ...
}:
{
  den.hosts.aarch64-darwin.mbp.users.${constants.user.chianyung.username} = { };

  den.aspects.mbp = {
    includes = [
      # <shell/homebrew>
      # <shell/aerospace>
      <shell/rex>

      <system/settings>
      <secrets/sops/mbp>
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          nil
          nh
        ];
      };

    darwin = {
      # Casks are inactive until <shell/homebrew> is enabled above.
      homebrew.casks = [ "aside" ];
    };
  };
}
