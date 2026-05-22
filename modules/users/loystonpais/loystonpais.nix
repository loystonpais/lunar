{
  den,
  lunar,
  lib,
  ...
}: {
  den.aspects.loystonpais = let
    infisical.projectId = "7387bfdf-3d2a-4397-8af6-dd4ff5f8fd6a";
  in {
    includes = [
      den.provides.primary-user
      (den.provides.user-shell "zsh")
      den.provides.define-user
    ];

    nixos = {
      pkgs,
      config,
      ...
    }: {
      time.timeZone = "Asia/Kolkata";

      i18n = {
        defaultLocale = "en_US.UTF-8";
        supportedLocales = [
          "en_US.UTF-8/UTF-8"
          "en_GB.UTF-8/UTF-8"
          "en_IN/UTF-8"
        ];
      };

      users.users.loystonpais = {
        extraGroups = ["networkmanager" "wheel" "disk" "i2c"];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHtN04FVSVonasScikFfltCPFJkSWa3t3z+wo+JA8GGd loyston500@gmail.com"
        ];
        initialPassword = "loystonpais";
      };

      environment.systemPackages = with pkgs; [
        lsd
        micro
        git
        fastfetch
        nh
        pciutils
        ripgrep
        file
        busybox
        python3
        ruby
        unar
        nil
        lsd
        tldr
        broot
        compsize
        alejandra
        jq
        rsync
        gh
        pass
        jq
        yq-go
        fzf
        bat
        # yt-dlp #! Dependency deno is broken on aarch64-linux
        fd
        libnotify
        zenity
        rbw
        pinentry-curses
        grim
        slurp
        yazi
        tmux
        zellij
        bubblewrap

        python3Packages.markitdown
      ];

      nix = {
        settings = {
          trusted-users = ["loystonpais"];
        };
      };

      security.acme = {
        defaults.email = "loyston500@gmail.com";
      };

      home-manager = {
        backupFileExtension = "nixbak";
        useGlobalPkgs = true;
        useUserPackages = true;
      };

      networking.networkmanager.enable = true;

      virtualisation.vmVariant.networking.hostName = lib.mkForce "${config.networking.hostName}-vm";

      programs.nix-ld.enable = true;

      programs.bash.blesh.enable = true;
    };

    homeManager = {pkgs, ...}: {
      home = {
        packages = with pkgs; [
          htop
        ];
      };

      programs.git = {
        enable = true;
        settings = {
          user.name = "loystonpais";
          user.email = "loyston500@gmail.com";
          alias = {
            pu = "push";
            ch = "checkout";
            cm = "commit";
          };
        };
      };

      home.stateVersion = lib.mkDefault "25.11";

      home.shellAliases = {
        ls = "lsd";
        lstr = "lsd -tr";
        lst = "lsd --tree";
        cpr = "rsync -avhP --partial --inplace";
      };

      home.sessionPath = [
        "$HOME/.local/bin"
        "$HOME/Downloads/bin"
      ];
    };

    provides.substituters = {
      nixos.nix.settings = {
        substituters = [
          "https://loystonpais.cachix.org?priority=10"
        ];
        trusted-public-keys = [
          "loystonpais.cachix.org-1:lclfaBitH51Lw9WwBxQ4bbesdt7c01JlFbKoSZ0PMLc="
        ];
      };
    };

    provides.roglaptop = {
      includes = [
        lunar.determinate
        lunar.audio
        lunar.cuda
        lunar.distrobox
        lunar.podman
        lunar.misc
        (lunar.plasma)
        lunar.browsers
        lunar.fonts
        lunar.graphics
        lunar.gaming
        (lunar.gamedev {cudaTools = true;})
        lunar.minecraft
        lunar.multimedia
        lunar.piracy
        lunar.kitty
        lunar.dev
        lunar.virt
        lunar.virt._.kvmfr
        lunar.virt._.evdev
        lunar.sops
        lunar.hm-home-symlinks
        lunar.asuslinux
        lunar.xonsh
        lunar.ssh
        lunar.vscode
        lunar.git
        lunar.hardware
        lunar.tailscale
        lunar.android
        lunar.devenv
        lunar.zed

        lunar.neovim
        lunar.neovim._.lazyvim-declarative
        lunar.neovim._.astronvim

        lunar.niri

        lunar.dms
        (lunar.dms._.via-systemd {desktops = ["niri"];})
        lunar.dms._.greeter
        lunar.dms._.default-browser

        lunar.agents
        (lunar.agents._.jailed (pkgs: {
            gemini = {
              pkg = pkgs.gemini-cli;
              perms = c:
                with c; [
                  (set-argv [
                    "--yolo"
                    (noescape "\"$@\"")
                  ])

                  (set-env "GEMINI_TELEMETRY_ENABLED" "0")
                ];
            };

            claude = {
              pkg = pkgs.claude-code;
            };

            opencode = {
              pkg = pkgs.opencode;
            };

            bash = {
              pkg = pkgs.bashInteractive;
            };
          }) (
            builtins.listToAttrs (map (scope: {
              name = scope;
              value.perms = c:
                with c; [];
            }) ["800" "200" "500" "1000"])
          ) {})

        lunar.infisical
        (lunar.infisical._.secret-sync {
          projectId = infisical.projectId;
          syncSec = "5h";
        })
      ];
    };

    provides.vili = {
      includes = [
        lunar.determinate
        lunar.ssh
        lunar.git
        lunar.dev

        lunar.agents
        (lunar.agents._.jailed (pkgs: {
            gemini = {
              pkg = pkgs.gemini-cli;
              perms = c:
                with c; [
                  (set-argv [
                    "--yolo"
                    (noescape "\"$@\"")
                  ])

                  (set-env "GEMINI_TELEMETRY_ENABLED" "0")
                ];
            };

            claude = {
              pkg = pkgs.claude-code;
            };

            opencode = {
              pkg = pkgs.opencode;
            };
          }) (
            builtins.listToAttrs (map (scope: {
              name = scope;
              value.perms = c:
                with c; [];
            }) ["800" "200" "500" "1000"])
          ) {})

        # TODO: Remove this later when the dep with lunar.dev is removed
        lunar.xonsh
      ];
    };

    provides.nixacle = {
      includes = [
        lunar.determinate
        lunar.tailscale
        lunar.ssh
        lunar.git
        lunar.dev
        lunar.sops

        lunar.server
        lunar.server._.linux-kernel-618-temp-boot-fix
        lunar.server._.oracle-alwaysfree-e2-instance
        lunar.server._.share-host-secrets
        lunar.server._.storage-management
        lunar.server._.vm-enhancements
        lunar.server._.no-ipv6

        lunar.acme
        (lunar.acme._.freedns-afraid {domainName = "loy.ftp.sh";})

        (lunar.rclone {
          remotes = [
            "dropbox500"
          ];
        })

        lunar.infisical
        (lunar.infisical._.secret-sync {
          projectId = infisical.projectId;
          syncSec = "1h";
        })

        # TODO: Remove this later when the dep with lunar.dev is removed
        lunar.xonsh
      ];
    };

    provides.diviner = {
      includes = [
        lunar.determinate
        lunar.tailscale
        lunar.ssh
        lunar.git
        lunar.dev
        lunar.sops

        lunar.server
        lunar.server._.linux-kernel-618-temp-boot-fix
        lunar.server._.oracle-alwaysfree-e2-instance
        lunar.server._.share-host-secrets
        lunar.server._.storage-management
        lunar.server._.vm-enhancements
        lunar.server._.no-ipv6

        lunar.acme
        (lunar.acme._.freedns-afraid {
          domainName = "diviner.loy.ftp.sh";
          cert = null;
        })

        # TODO: Remove this later when the dep with lunar.dev is removed
        lunar.xonsh
      ];
    };
  };
}
