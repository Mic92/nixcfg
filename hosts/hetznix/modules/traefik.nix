{ config, lib, inputs, ... }:

{
  age.secrets.cloudflare_api_key.file = "${inputs.self}/secrets/cloudflare_api_key.age";

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  systemd.services.traefik = {
    environment = {
      CF_API_EMAIL = "cloudflare@croughan.sh";
    };
    serviceConfig = {
      EnvironmentFile = config.age.secrets.cloudflare_api_key.path;
    };
  };

  services.traefik = {
    enable = true;

    dynamicConfigOptions = {
      http.middlewares.redirect-to-https.redirectscheme = {
        scheme = "https";
        permanent = true;
      };
      http = {
        services = {
          vaultwarden.loadBalancer.servers = [ { url = "http://127.0.0.1:8222"; } ];
        };
        routers = {
          vaultwarden-insecure = {
            rule = "Host(`vaultwarden.croughan.sh`)";
            entryPoints = [ "web" ];
            service = "vaultwarden";
            middlewares = "redirect-to-https";
          };
          vaultwarden = {
            rule = "Host(`vaultwarden.croughan.sh`)";
            entryPoints = [ "websecure" ];
            service = "vaultwarden";
            tls.certresolver = "letsencrypt";
          };
        };
      };
    };

    staticConfigOptions = {
      global = {
        checkNewVersion = false;
        sendAnonymousUsage = false;
      };

      entryPoints.web.address = ":80";
      entryPoints.websecure.address = ":443";
      certificatesResolvers = {
        letsencrypt.acme = {
          email = "letsencrypt@croughan.sh";
#          caServer = "https://acme-staging-v02.api.letsencrypt.org/directory";
          storage = "/var/lib/traefik/cert.json";
          dnsChallenge = {
            provider = "cloudflare";
            delayBeforeCheck = 0;
          };
        };
      };
    };
  };
}
