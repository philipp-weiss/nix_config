{ config, ... }:
{
  age.secrets.gatus-htpasswd = {
    rekeyFile = ../../secrets/gatus-htpasswd.age;
    owner = "nginx";
  };

  # Shared secret for the nightly-backup heartbeat (env file: GATUS_BACKUP_TOKEN=...).
  # Read by systemd as root before launching gatus, so default agenix perms are fine.
  age.secrets.gatus-heartbeat-token.rekeyFile = ../../secrets/gatus-heartbeat-token.age;

  services.gatus = {
    enable = true;
    environmentFile = config.age.secrets.gatus-heartbeat-token.path;
    settings = {
      web = {
        address = "127.0.0.1";
        port = 8080;
      };

      ui = {
        title = "pweiss status";
        header = "Status";
      };

      endpoints = [
        {
          name = "vaultwarden";
          group = "web";
          url = "https://vaultwarden.pweiss.org";
          interval = "5m";
          conditions = [
            "[STATUS] == 200"
            "[CERTIFICATE_EXPIRATION] > 168h"
          ];
        }
        {
          name = "restic-server";
          group = "web";
          # rest-server is htpasswd-protected: 401 without auth proves it's alive.
          url = "https://restic.pweiss.org/";
          interval = "5m";
          conditions = [
            "[STATUS] == 401"
            "[CERTIFICATE_EXPIRATION] > 168h"
          ];
        }
      ];

      # Heartbeat from nuc's nightly restic backup. nuc POSTs on success; if no
      # push arrives within heartbeat.interval, gatus marks this endpoint DOWN.
      external-endpoints = [
        {
          name = "nightly-backup";
          group = "cron";
          token = "\${GATUS_BACKUP_TOKEN}";
          heartbeat.interval = "25h";
        }
      ];
    };
  };

  services.nginx.virtualHosts."status.pweiss.org" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8080";
      basicAuthFile = config.age.secrets.gatus-htpasswd.path;
    };
    # Heartbeat push endpoint must be reachable without basic auth — gatus
    # authenticates these requests with the bearer token. Regex location wins
    # over the prefix `/` location only for this exact path shape.
    locations."~ ^/api/v1/endpoints/[^/]+/external$" = {
      proxyPass = "http://127.0.0.1:8080";
    };
  };
}
