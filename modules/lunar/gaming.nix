{den, ...}: {
  lunar.gaming = {user, ...}: {
    nixos = {pkgs, ...}: {
      boot.kernelModules = ["ntsync"];

      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
      };

      environment.systemPackages = with pkgs; [
        protonup-qt
        heroic
        antimicrox
        mangohud
        #! bottles # Build failure
        piper
      ];

      # Feral gamemode setup
      programs.gamemode.enable = true;

      users.users.${user.userName}.extraGroups = ["gamemode"];

      # For mouse and keyboard configuration
      services.ratbagd.enable = true;
    };
  };
}
