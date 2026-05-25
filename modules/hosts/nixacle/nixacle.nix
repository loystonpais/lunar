{den, ...}: {
  den.aspects.nixacle = {
    includes = [
      den.aspects.loystonpais
    ];

    nixos = {
      pkgs,
      lib,
      ...
    }: {
      imports = [
        ./_infect/configuration.nix
      ];

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [25565 80 443];
      };

      security.acme.certs."loy.ftp.sh".listenHTTP = lib.mkForce null;

      services.nginx = {
        enable = true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;

        virtualHosts = {
          "matrix.loy.dedyn.io" = {
            forceSSL = true;
            enableACME = true;

            locations."/" = {
              proxyPass = "http://localhost:6167";
              proxyWebsockets = true;
            };
          };
        };

        virtualHosts."loy.ftp.sh" = {
          enableACME = true;
          forceSSL = true;

          locations = {
            "/" = {
              proxyPass = "http://localhost:5000";
              extraConfig = ''
                client_max_body_size 512M;
                proxy_set_header Connection $http_connection;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
              '';
            };

            "/projects/fake-online-test" = {
              root = "/var/www";
              extraConfig = ''
                expires -1;
                add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate";
              '';
              tryFiles = "$uri $uri/ =404";
            };
          };
        };
      };

      # Matrix Continuwuity
      services.matrix-continuwuity = {
        enable = true;
        admin.enable = true;
        settings.global = {
          address = "127.0.0.1";
          port = 6167;
          server_name = "matrix.loy.dedyn.io";
          allow_encryption = true;
          allow_federation = true;
          allow_registration = false;
          trusted_servers = ["matrix.org"];
        };
      };
    };
  };
}
