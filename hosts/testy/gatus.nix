{ config, ... }:
{
  age.secrets.gatus-htpasswd = {
    rekeyFile = ../../secrets/gatus-htpasswd.age;
    owner = "nginx";
  };

  services.gatus = {
    enable = true;
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
    };
  };

  services.nginx.virtualHosts."status.pweiss.org" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8080";
      basicAuthFile = config.age.secrets.gatus-htpasswd.path;
    };
  };
}
