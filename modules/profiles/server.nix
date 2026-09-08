{ __findFile, ... }:
{
  den.aspects.profile._.server = {
    description = "Shared server system capabilities";

    includes = [
      <system/locale>
      <system/sshd>
    ];
  };
}
