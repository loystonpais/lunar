{
  den,
  lunar,
  lib,
  inputs,
  ...
}: {
  #flake.den = den;

  den.aspects.roglaptop = {
    includes = [
      den.aspects.loystonpais
    ];

    nixos = {
      pkgs,
      lib,
      config,
      ...
    }: {
      imports = [
        ./_hw
        ./_vfio

        inputs.linuwowo.nixosModules.default
        {
          specialisation.linuwowo.configuration = {
            programs.linuwowo = {
              enable = true;
              json = ./_hw/linuwowo.json;
            };
          };
        }

        # Cachyos kernel
        {
          # nixpkgs.overlays = [inputs.nix-cachyos-kernel.overlays.pinned];
          # boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
          # system.nixos.tags = ["cachyos"];
          # boot.kernelParams = ["preempt=full"];
        }

        {
          hardware.nvidia.package = lib.mkForce config.boot.kernelPackages.nvidiaPackages.latest;
        }

        {
          networking.networkmanager.wifi.powersave = false;

          boot.kernel.sysctl = {
            "net.ipv4.tcp_mtu_probing" = 1;
            "net.ipv4.tcp_congestion_control" = "bbr";
            "net.core.default_qdisc" = "cake";
          };

          boot.kernelModules = ["tcp_bbr" "sch_cake"];
        }
      ];

      fileSystems."/mnt/windows" = {
        device = "/dev/disk/by-uuid/BA16A4A516A463DB";
        fsType = "ntfs-3g";
        options = ["nofail" "rw"];
      };

      environment.systemPackages = with pkgs; [
        ddcutil

        gparted
        ayugram-desktop
        obsidian
        baobab
        ente-auth
      ];

      services.flatpak.enable = true;

      networking.dhcpcd.enable = false;
      networking.networkmanager.unmanaged = [
        "interface-name:ve-*"
        "interface-name:microbr"
        "interface-name:microvm*"
      ];
      networking.firewall.enable = lib.mkForce false;

      hardware.nvidia.prime = {
        offload.enable = true;
        offload.enableOffloadCmd = true;
      };

      # TODO: See if enabling these causes random crashes
      # UPDATE: Haven't seen any crashes since enabling finegrained
      hardware.nvidia = {
        powerManagement.enable = lib.mkForce true;
        powerManagement.finegrained = lib.mkForce true;
        open = lib.mkForce true;
      };

      # REMINDER: Temporary workaround to delay supergfxd via timer to isolate early boot / greeter crashes. Remove later.
      systemd.services.supergfxd = {
        before = lib.mkForce [];
        wantedBy = lib.mkForce [];
      };

      systemd.timers.supergfxd = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnBootSec = "30s";
          Unit = "supergfxd.service";
        };
      };

      boot.loader.grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        device = "nodev";
      };

      boot.tmp.cleanOnBoot = true;
      boot.binfmt.emulatedSystems = ["aarch64-linux"];

      system.stateVersion = "23.11";

      virtualisation.vmVariant.system.stateVersion = config.system.stateVersion;

      security.rtkit.enable = true;
      programs.nix-ld.enable = true;
    };
  };

  den.aspects.roglaptop.provides.to-users = {user, ...}: {
    users.users.${user.userName}.extraGroups = ["i2c"];
  };
}
