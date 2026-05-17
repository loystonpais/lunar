{
  den,
  lunar,
  lib,
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
