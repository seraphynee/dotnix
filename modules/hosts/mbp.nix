{
  __findFile,
  constants,
  ...
}:
{
  den.hosts.aarch64-darwin.mbp.users.${constants.user_one} = { };

  den.aspects.mbp = {
    includes = [
      # <shell/homebrew>
      # <shell/aerospace>

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

    darwin = { };
  };
}
