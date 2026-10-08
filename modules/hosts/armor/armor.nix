{den, ...}: {
  den.aspects.armor = {
    includes = [
      den.aspects.loystonpais

      #### RANDOMMC ####
      {
        nixos = {
          services.caddy = {
            enable = true;

            virtualHosts."randommc.loy.dedyn.io:25585" = {
              extraConfig = ''
                redir /serve /serve/

                handle /serve* {
                  reverse_proxy 127.0.0.1:25587
                }

                handle {
                  reverse_proxy 127.0.0.1:25586
                }
              '';
            };
          };

          networking.firewall.allowedTCPPorts = [80 25565 25585];
        };
      }
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

      networking.firewall.allowedTCPPorts = [1080];
    };
  };
}
