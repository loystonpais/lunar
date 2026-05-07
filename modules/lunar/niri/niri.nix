{
  den,
  lib,
  inputs,
  lunar,
  ...
}: {
  lunar.niri = {
    includes = [
      lunar.niri._.fix-webrtc
    ];

    nixos = {pkgs, ...}: {
      imports = [
        inputs.niri.nixosModules.niri
      ];

      programs.niri = {
        enable = true;
        package = pkgs.niri;
      };

      environment.systemPackages = with pkgs; [
        xwayland-satellite
        labwc

        ghostty
        alacritty
      ];

      services.displayManager.dms-greeter.compositor.name = lib.mkDefault "niri";

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          kdePackages.xdg-desktop-portal-kde
          xdg-desktop-portal-gtk
          xdg-desktop-portal-gnome
        ];
        config.common.default = "gnome";
        #config.niri."org.freedesktop.impl.portal.FileChooser" = ["kde"];
      };

      systemd.user.services.kded6 = {
        description = "KDE Daemon";
        wantedBy = ["graphical-session.target"];
        partOf = ["graphical-session.target"];
        after = ["graphical-session.target"];
        serviceConfig = {
          ExecStart = "${pkgs.kdePackages.kded}/bin/kded6";
          Restart = "on-failure";
          Slice = "session.slice";
          # FIX: Explicitly pass the prefix so kded6 looks for 'plasma-applications.menu'
          Environment = "XDG_MENU_PREFIX=plasma-";
        };
      };

      # Stuff below apparently fixes timeout issues
      systemd.user.services.xdg-desktop-portal = {
        serviceConfig = {
          TimeoutStartSec = "10s";
        };
      };

      systemd.user.services.xdg-desktop-portal-gnome = {
        serviceConfig = {
          TimeoutStartSec = "10s";
        };
      };

      systemd.user.services.xdg-desktop-portal-gtk = {
        serviceConfig = {
          TimeoutStartSec = "10s";
        };
      };

      # # Increase inotify limits for apps that watch many files (Spotify, VS Code, etc.)
      ### boot.kernel.sysctl."fs.inotify.max_user_instances" = 8192;
    };

    homeManager = {
      pkgs,
      config,
      ...
    }: {
      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
        ];
      };

      programs.niri.settings = {
      };
    };

    provides.cache = {
      nixos.niri-flake.cache.enable = true;
    };

    provides.fix-webrtc = {
      homeManager = {pkgs, ...}: {
        xdg.portal = {
          enable = true;
          extraPortals = with pkgs; [
            xdg-desktop-portal-gtk
            xdg-desktop-portal-gnome
          ];
          configPackages = with pkgs; [
            xdg-desktop-portal-gtk
            xdg-desktop-portal-gnome
          ];
        };
      };
    };
  };
}
