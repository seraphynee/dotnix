{
  __findFile,
  constants,
  ...
}:
{
  den.hosts.aarch64-darwin.mbp.users.${constants.users.chianyung} = { };

  den.aspects.mbp = {
    includes = [
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
