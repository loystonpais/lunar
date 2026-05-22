{den, ...}: {
  den.aspects.diviner = {
    includes = [
      den.aspects.loystonpais
    ];

    nixos = {
      pkgs,
      config,
      ...
    }: {
      imports = [
        ./_infect/configuration.nix
      ];

      environment.systemPackages = with pkgs; [
        tmux
        nh
        bat
      ];

      services._3proxy = {
        enable = true;
        services = [
          {
            type = "socks";
            auth = ["strong"];
            acl = [
              {
                rule = "allow";
                users = ["loystonpais" "evilnosoul"];
              }
            ];
          }
        ];

        usersFile = "/var/lib/3proxy/users";
      };

      networking.firewall.allowedTCPPorts = [1080];
    };
  };
}
