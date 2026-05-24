{
  den,
  inputs,
  lib,
  ...
}: {
  lunar.sops = {
    host,
    user,
    ...
  }: {
    nixos = {
      config,
      pkgs,
      ...
    }: let
      vars = config.sops.secrets or {};
    in {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      sops = {
        defaultSopsFile = "${inputs.self.outPath}/secrets/secrets.yaml";
        defaultSopsFormat = "yaml";
      };

      environment.systemPackages = with pkgs; [
        sops
        ssh-to-age
        nano
      ];

      sops.secrets = {
        groq-personal-use-key.owner = user.userName;
        groq-key-portfolio-site.owner = user.userName;
        groq-key-800-personal.owner = user.userName;

        gemini-api-key.owner = user.userName;
        github-key.owner = user.userName;
        openrouter-key.owner = user.userName;
        cachix-loystonpais-auth-token.owner = user.userName;

        wireguard-server-common-private-key.owner = user.userName;

        mc-offline-username.owner = user.userName;
        mc-offline-uuid.owner = user.userName;

        "business-profile.jpg" = {
          format = "binary";
          sopsFile = ../../secrets/files/business-profile.jpg.enc;
          owner = user.userName;
        };
        "college-logo.jpg" = {
          format = "binary";
          sopsFile = ../../secrets/files/college-logo.jpg.enc;
          owner = user.userName;
        };
        "rclone.conf" = {
          format = "ini";
          sopsFile = ../../secrets/rclone.ini;
          owner = user.userName;
        };

        ataraxy-bot-token.owner = user.userName;
        ataraxy-environment-file.owner = user.userName;

        nixacle-gitea-db-password.owner = user.userName;
        gitea-key.owner = user.userName;

        "freedns-afraid-domains/loy.ftp.sh/update-url".owner = user.userName;
        "freedns-afraid-domains/diviner.loy.ftp.sh/update-url".owner = user.userName;
        "freedns-afraid-domains/loy.us.to/update-url".owner = user.userName;
      };
    };

    homeManager = {osConfig, ...}: let
      vars = {
        GROQ_API_KEY = osConfig.sops.secrets.groq-personal-use-key;
        GITHUB_KEY = osConfig.sops.secrets.github-key;

        CACHIX_LOYSTONPAIS_AUTH_TOKEN = osConfig.sops.secrets.cachix-loystonpais-auth-token;
        CACHIX_AUTH_TOKEN = osConfig.sops.secrets.cachix-loystonpais-auth-token;

        OPENROUTER_KEY = osConfig.sops.secrets.openrouter-key;

        MC_OFFLINE_USERNAME = osConfig.sops.secrets.mc-offline-username;
        MC_OFFLINE_UUID = osConfig.sops.secrets.mc-offline-uuid;
      };

      toEnvVar = str:
        lib.toUpper (
          builtins.replaceStrings
          ["-" "." " " "/"]
          ["_" "_" "_" "_"]
          str
        );
    in {
      programs.zsh.initContent = lib.mkIf (vars != {}) (
        builtins.concatStringsSep "\n" (map (name: ''export '${name}'="$(cat ${vars.${name}.path})"'') (builtins.attrNames vars))
      );

      home.file.".profile".text = lib.mkIf (vars != {}) (
        builtins.concatStringsSep "\n" (map (name: ''export '${name}'="$(cat ${vars.${name}.path})"'') (builtins.attrNames vars))
      );
    };
  };
}
