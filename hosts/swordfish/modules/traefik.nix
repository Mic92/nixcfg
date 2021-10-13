{ config, lib, ... }:

{
  age.secrets.cloudflare_api_key.file = ../../../secrets/cloudflare_api_key.age;

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
          crater.loadBalancer.servers = [ { url = "http://127.0.0.1:8070"; } ];
          jellyfin.loadBalancer.servers = [ { url = "http://127.0.0.1:8096"; } ];
        };
        routers = {
          jellyfin-insecure = {
            rule = "Host(`jellyfin.gamecu.be`)";
            entryPoints = [ "web" ];
            service = "jellyfin";
            middlewares = "redirect-to-https";
          };
          jellyfin = {
            rule = "Host(`jellyfin.gamecu.be`)";
            entryPoints = [ "websecure" ];
            service = "jellyfin";
            tls.certresolver = "letsencrypt";
          };
          crater-insecure = {
            rule = "Host(`crater.gamecu.be`)";
            entryPoints = [ "web" ];
            service = "crater";
            middlewares = "redirect-to-https";
          };
          crater = {
            rule = "Host(`crater.gamecu.be`)";
            entryPoints = [ "websecure" ];
            service = "crater";
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
