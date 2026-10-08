{
  den,
  inputs,
  lunar,
  lib,
  ...
}: {
  lunar.dms = {
    includes = [
      lunar.kitty

      lunar.dms._.theme-fixes
      lunar.dms._.fix-java-apps
      lunar.dms._.kde-dolphin-integration
      lunar.dms._.kvantum-themes

      lunar.wayland._.tools
      lunar.audio._.tools
    ];
    nixos = {
      pkgs,
      config,
      inputs',
      ...
    }: {
      environment.systemPackages = with pkgs; [
        kdePackages.qt6ct
        libsForQt5.qt5ct
        kdePackages.qtstyleplugin-kvantum

        (whitesur-icon-theme.override {
          alternativeIcons = true;
          boldPanelIcons = true;
        })
        whitesur-cursors

        papirus-icon-theme

        kdePackages.dolphin
        kdePackages.ark
        kdePackages.gwenview

        nautilus
      ];

      services.upower.enable = true;
      services.power-profiles-daemon.enable = true;
      services.accounts-daemon.enable = true;

      #### NIRI

      # Disable niri-flake's own polkit to allow dms's own
      # NOTE: This USER service is defined in NIXOS not homeManager
      systemd.user.services.niri-flake-polkit.enable = false;

      ####
    };

    homeManager = {
      pkgs,
      lib,
      config,
      ...
    }: let
      set-dms-dolphin-theme = pkgs.writeShellScriptBin "set-dms-dolphin-theme" ''
        touch "${config.home.homeDirectory}/.config/dolphinrc" || true
        ${lib.getExe pkgs.initool} set "${config.home.homeDirectory}/.config/dolphinrc" UiSettings ColorScheme DankMatugen > "${config.home.homeDirectory}/.config/dolphinrc"
      '';
    in {
      imports = [
        inputs.dms.homeModules.dank-material-shell
        inputs.dms.homeModules.niri
      ];

      systemd.user.services.dms = {
        Service = {
          Environment = [
            "QT_QPA_PLATFORMTHEME=qt6ct"
            "QT_QPA_PLATFORMTHEME_QT6=qt6ct"
          ];

          UnsetEnvironment = "QT_STYLE_OVERRIDE";
        };
      };

      programs.niri.settings = {
        environment = {
          QT_QPA_PLATFORMTHEME = "qt6ct";
          QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
          QT_STYLE_OVERRIDE = "";
        };

        spawn-at-startup = [
          {argv = ["${lib.getExe set-dms-dolphin-theme}"];}
        ];
      };

      home.packages = [set-dms-dolphin-theme];

      programs.dank-material-shell = {
        enable = true;

        niri = {
          includes.filesToInclude = [
            "alttab"
            "binds"
            "colors"
            "cursor"
            "layout"
            "outputs"
            "windowrules"
            "wpblur"
          ];
        };
      };

      #### NIRI

      #! Just make it work for Niri
      xdg.configFile.niri-config-dms.text =
        (
          lib.mkIf
          (config.home.file.".config/niri/mutable.kdl" or {enable = false;}).enable
        )
        ''
          include "./mutable.kdl"
        '';

      ####
    };

    provides.default-browser = {
      homeManager = {
        pkgs,
        lib,
        ...
      }: {
        xdg.mimeApps = {
          enable = true;
          defaultApplications = {
            "x-scheme-handler/http" = "dms-open.desktop";
            "x-scheme-handler/https" = "dms-open.desktop";
          };
        };
      };
    };

    provides.greeter = {
      user,
      compositor ? null,
      ...
    }: {
      nixos = {config, ...}: {
        imports = [
          inputs.dank-greeter.nixosModules.default
        ];

        programs.dms-greeter = {
          enable = true;
          configHome = config.home-manager.users.${user.userName}.home.homeDirectory;
          compositor.name = lib.mkIf (compositor != null) compositor;
        };

        #TODO: Check this out
        # https://github.com/AvengeMedia/DankMaterialShell/issues/2054
      };
    };

    provides.via-systemd = {desktops ? null, ...}: let
      desktopPattern = builtins.concatStringsSep "|" desktops;
    in {
      homeManager = {
        pkgs,
        lib,
        ...
      }: {
        programs.dank-material-shell = {
          systemd = {
            enable = true;
            restartIfChanged = true;
          };
        };

        systemd.user.services.dms.Service.ExecCondition = lib.mkIf (desktops != null) "${lib.getExe pkgs.bash} -c 'case \"$XDG_CURRENT_DESKTOP\" in ${desktopPattern}) exit 0;; *) exit 1;; esac'";
      };
    };

    provides.fix-java-apps = {
      homeManager = {...}: {
        systemd.user.services.dms = {
          Service = {
            Environment = [
              "_JAVA_AWT_WM_NONREPARENTING=1"
            ];
          };
        };
      };
    };

    provides.kde-dolphin-integration = {
      nixos = {
        pkgs,
        config,
        ...
      }: {
        environment.systemPackages = with pkgs; [
          kdePackages.dolphin

          kdePackages.kservice # This needs be in path for MIME menus to work in dolphin

          # By default, dolphin by itself is not packaged with support for svg icons. This may result in blank icons.
          kdePackages.qtsvg

          # https://gist.github.com/linhusp/05f8f7e0af3fa0fbb944dec17a75aa78
          kdePackages.systemsettings
          kdePackages.xdg-desktop-portal-kde
          kdePackages.ffmpegthumbs
          ffmpegthumbnailer
        ];

        # https://github.com/barsikus007/config/blob/055e386319459175df2382910e400613e888c6dc/nix/modules/desktop/environment/explorer/dolphin.nix
        #? Fix unpopulated MIME menus in dolphin: https://discourse.nixos.org/t/dolphin-does-not-have-mime-associations/48985/8
        # Make sure kservice is in path
        environment.etc."xdg/menus/applications.menu" = {
          enable = !config.services.desktopManager.plasma6.enable;
          text = builtins.readFile "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";
        };
      };
    };

    provides.kvantum-themes = {
      nixos = {
        pkgs,
        config,
        ...
      }: {
        environment.systemPackages = with pkgs; [
          catppuccin-kvantum
          rose-pine-kvantum
        ];

        environment.pathsToLink = [
          "/share"
        ];
      };
    };

    provides.theme-fixes = {
      includes = [
        # https://github.com/AvengeMedia/DankMaterialShell/issues/2070
        {
          homeManager = {pkgs, ...}: {
            home.packages = with pkgs; [
              adw-gtk3
            ];

            dconf.enable = true;

            dconf.settings = {
              "org/gnome/desktop/interface" = {
                gtk-theme = "adw-gtk3-dark";
                color-scheme = "prefer-dark";
              };
            };
          };
        }

        # https://discourse.nixos.org/t/dolphin-theming-help-qt/68407/2
        {
          nixos = {pkgs, ...}: {
            environment = {
              systemPackages = with pkgs; [
                libsForQt5.qt5ct
                kdePackages.qt6ct
                adwaita-qt
              ];
              sessionVariables = {
                QT_QPA_PLATFORMTHEME = "qt5ct";
              };
              etc = {
                "xdg/qt5ct/qt5ct.conf".text = ''
                  [Appearance]
                  style=adwaita-dark
                '';
                "xdg/qt6ct/qt6ct.conf".text = ''
                  [Appearance]
                  style=adwaita-dark
                '';
              };
            };
          };
        }
      ];
    };

    provides.via-niri = {
      nixos = {...}: {};

      homeManager = {
        lib,
        config,
        ...
      }: {
        programs.dank-material-shell = {
          niri = {
            enableSpawn = true;
          };
        };
      };
    };
  };
}
