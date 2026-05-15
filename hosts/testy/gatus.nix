{ config, pkgs, ... }:
{
  # Token for gatus external-endpoint pushes (env file: GATUS_BACKUP_TOKEN=...).
  # Used by both gatus (to validate pushes) and the backup-check timer (to push).
  age.secrets.gatus-heartbeat-token.rekeyFile = ../../secrets/gatus-heartbeat-token.age;

  services.gatus = {
    enable = true;
    environmentFile = config.age.secrets.gatus-heartbeat-token.path;
    settings = {
      web = {
        address = "0.0.0.0";
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
          # Probed over loopback since the service is tailnet-only and gatus runs
          # on the same host.
          url = "http://127.0.0.1:8000/";
          interval = "5m";
          conditions = [
            "[STATUS] == 401"
          ];
        }
      ];

      # Heartbeat for the nightly restic backup. The restic-backup-check timer
      # below pushes daily after inspecting /var/lib/restic/nuc/snapshots mtime.
      # If no push arrives within heartbeat.interval, gatus marks this DOWN.
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

  # Reachable only via tailnet; public interface stays default-deny.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8080 ];

  # Daily freshness check: looks at the rest-server's data dir and pushes
  # success/failure to gatus's external endpoint. Runs as `restic` so it can
  # stat snapshot files. 1500 minutes = 25h (one timer interval grace beyond
  # the 02:00 backup).
  systemd.services.restic-backup-check = {
    description = "Check nuc restic backup freshness and push to gatus";
    path = [ pkgs.curl pkgs.findutils ];
    serviceConfig = {
      Type = "oneshot";
      User = "restic";
      Group = "restic";
      EnvironmentFile = config.age.secrets.gatus-heartbeat-token.path;
    };
    script = ''
      if find /var/lib/restic/nuc/snapshots -type f -mmin -1500 -print -quit | grep -q .; then
        url="http://127.0.0.1:8080/api/v1/endpoints/cron_nightly-backup/external?success=true"
      else
        url="http://127.0.0.1:8080/api/v1/endpoints/cron_nightly-backup/external?success=false&error=stale"
      fi
      exec curl -fsS --max-time 30 -X POST \
        -H "Authorization: Bearer $GATUS_BACKUP_TOKEN" "$url"
    '';
  };

  systemd.timers.restic-backup-check = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "02:30";
      Persistent = true;
    };
  };
}
