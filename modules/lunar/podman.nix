{den, ...}: {
  lunar.podman = {
    user,
    enableDocker ? true,
    ...
  }: {
    nixos = {
      pkgs,
      lib,
      config,
      ...
    }: {
      config = lib.mkMerge [
        {
          virtualisation.podman = {
            enable = true;
            dockerCompat = !enableDocker;
          };

          environment.systemPackages = with pkgs; [
            podman-compose
            podman-tui
          ];

          users.users.${user.userName} = {
            extraGroups = ["podman"];
            subGidRanges = [
              {
                count = 65536;
                startGid = 10000;
              }
            ];
            subUidRanges = [
              {
                count = 65536;
                startUid = 10000;
              }
            ];
          };
        }

        {
          virtualisation.docker = {
            enable = false;

            rootless = {
              enable = true;
              setSocketVariable = true;
            };
          };
        }
      ];
    };
  };
}
