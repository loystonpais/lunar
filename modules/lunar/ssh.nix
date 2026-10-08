{den, ...}: {
  lunar.ssh = {
    nixos = {pkgs, ...}: {
      services.openssh = {
        enable = true;
        ports = [22];
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          X11Forwarding = false;
          PermitRootLogin = "prohibit-password";
        };
      };

      networking.firewall.allowedTCPPorts = [22];

      programs.mosh.enable = true;
      networking.firewall.allowedUDPPortRanges = [
        {
          from = 60000;
          to = 61000;
        }
      ];

      environment.systemPackages = with pkgs; [proxychains-ng];
    };

    homeManager = {...}: {
      programs.ssh = {
        enableDefaultConfig = false;
        enable = true;
        settings = {
          "*" = {
            SetEnv = {
              # https://ghostty.org/docs/help/terminfo#configure-ssh-to-fall-back-to-a-known-terminfo-entry
              TERM = "xterm-256color";
            };
          };
          # pureintent = {
          #   forwardAgent = true;
          # };
        };
      };
    };
  };
}
