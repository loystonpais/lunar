{den, ...}: {
  lunar.infisical = {
    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [infisical];
    };

    provides.secret-sync = {
      projectId,
      syncSec ? "15min",
      env ? null,
      ...
    }: {
      description = "Sync Infisical secrets for a user";
      includes = [
        ({
          host,
          user,
          ...
        }: let
          mkPaths = homeDir: rec {
            dir = "${homeDir}/.infisical-secret-sync";
            envFile = "${dir}/secrets.env";
            envFileTmp = "${envFile}.tmp";

            mappedSecretsDir = "${dir}/secrets";
          };
        in {
          nixos = {
            pkgs,
            lib,
            config,
            ...
          }:
            with (mkPaths (config.users.users.${user.userName}.home)); {
              systemd.services."infisical-secret-sync-${user.userName}" = {
                after = ["network-online.target"];
                wants = ["network-online.target"];

                serviceConfig = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                  User = user.userName;

                  RuntimeDirectory = "infisical/${user.userName}";

                  ExecStart = pkgs.writeShellScript "infisical-sync-${user.userName}" ''
                    set -euo pipefail

                    export INFISICAL_DISABLE_UPDATE_CHECK=true

                    mkdir -p "${dir}" || true

                    ${pkgs.infisical}/bin/infisical export \
                      --projectId "${projectId}" \
                      ${lib.optionalString (env != null) "--env ${env}"} \
                      --format dotenv \
                      > "${envFileTmp}"

                    mv "${envFileTmp}" ${envFile}
                    chmod 600 "${envFile}"

                    mkdir -p "${mappedSecretsDir}"

                    # Collect current secret keys from the env file
                    declare -A current_keys
                    while IFS= read -r line || [[ -n "$line" ]]; do
                      [[ "$line" =~ ^[[:space:]]*# ]] && continue
                      [[ -z "''${line// }" ]] && continue
                      key="''${line%%=*}"
                      value="''${line#*=}"
                      value="''${value#\"}" value="''${value%\"}"
                      value="''${value#\'}" value="''${value%\'}"
                      [[ -z "$key" ]] && continue
                      printf '%s' "$value" > "${mappedSecretsDir}/$key"
                      current_keys["$key"]=1
                    done < "${envFile}"

                    # Remove secrets that no longer exist
                    for secret_file in "${mappedSecretsDir}"/*; do
                      [[ -e "$secret_file" ]] || continue
                      fname="$(basename "$secret_file")"
                      if [[ -z "''${current_keys[$fname]+_}" ]]; then
                        rm -f "$secret_file"
                      fi
                    done
                  '';

                  ProtectHome = false;
                  PrivateTmp = true;
                };
              };

              systemd.timers."infisical-secret-sync-${user.userName}" = {
                wantedBy = ["timers.target"];
                timerConfig = {
                  OnBootSec = "1min";
                  OnUnitActiveSec = syncSec;
                  Persistent = true;
                };
              };
            };

          homeManager = {config, ...}:
            with (mkPaths (config.home.homeDirectory)); {
              programs.zsh.initContent = ''
                if [ -f "${envFile}" ]; then
                  set -a
                  source "${envFile}"
                  set +a
                fi
              '';

              programs.bash.initExtra = ''
                if [ -f "${envFile}" ]; then
                  set -a
                  source "${envFile}"
                  set +a
                fi
              '';
            };
        })
      ];
    };
  };
}
