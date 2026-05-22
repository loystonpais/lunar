{
  den,
  lunar,
  lib,
  ...
}: {
  lunar.acme = {
    nixos = {pkgs, ...}: {
      security.acme = {
        acceptTerms = true;
      };
    };

    provides.freedns-afraid = {
      domainName,
      cert ? {listenHTTP = ":80";},
      ...
    }: let
      domainToServiceName = domain: "acme-${builtins.replaceStrings ["."] ["-"] domain}";
    in {
      nixos = {
        pkgs,
        config,
        ...
      }: {
        security.acme = {
          acceptTerms = true;
          certs = {
            "${domainName}" = lib.mkIf (cert != null) cert;
          };
        };

        systemd.services."acme-dns-update-${domainName}" = {
          enable = true;
          path = with pkgs; [curl];
          # script' = "curl -fsS $(cat ${config.sops.secrets."freedns-afraid-domains/${domainName}/update-url".path})";
          script = ''
            for i in $(seq 1 5); do
              curl -fsS $(cat ${config.sops.secrets."freedns-afraid-domains/${domainName}/update-url".path}) && exit 0
              sleep 3
            done
            exit 1
          '';
          before = ["acme-${domainName}.service"];
          serviceConfig = {
            Type = "oneshot";
          };
          wants = ["network-online.target"];
          after = ["network-online.target"];
          wantedBy = ["multi-user.target"];
        };

        # Let's just disable this for VMs
        virtualisation.vmVariant.systemd.services."acme-dns-update-${domainName}".enable = lib.mkForce false;
        virtualisation.vmVariant.systemd.services."acme-${domainName}".enable = lib.mkForce false;
      };
    };
  };
}
