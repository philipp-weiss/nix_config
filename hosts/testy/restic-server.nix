{ config, pkgs, ... }:
{
  environment.systemPackages = [ pkgs.restic ];

  age.secrets.restic-htpasswd = {
    file = ../../secrets/restic-htpasswd.age;
    owner = "restic";
  };

  age.secrets.restic-password = {
    file = ../../secrets/restic-password.age;
  };

  services.restic.server = {
    enable = true;
    dataDir = "/var/lib/restic";
    listenAddress = "127.0.0.1:8000";
    extraFlags = [
      "--htpasswd-file" config.age.secrets.restic-htpasswd.path
      "--append-only"
    ];
  };

  services.nginx.virtualHosts."restic.pweiss.org" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8000";
    };
  };

  # Pruning must run server-side because the client is append-only
  systemd.services.restic-prune-nuc = {
    description = "Prune restic backups for nuc";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.restic}/bin/restic -r /var/lib/restic/nuc --password-file ${config.age.secrets.restic-password.path} forget --prune --keep-daily 7 --keep-weekly 4 --keep-monthly 3";
    };
  };

  systemd.timers.restic-prune-nuc = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun 03:00";
      Persistent = true;
    };
  };
}
