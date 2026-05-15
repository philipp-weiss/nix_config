{ config, pkgs, ... }:
{
  environment.systemPackages = [ pkgs.restic ];

  age.secrets.restic-htpasswd = {
    rekeyFile = ../../secrets/restic-htpasswd.age;
    owner = "restic";
  };

  age.secrets.restic-password = {
    rekeyFile = ../../secrets/restic-password.age;
    owner = "restic";
  };

  services.restic.server = {
    enable = true;
    dataDir = "/var/lib/restic";
    listenAddress = "0.0.0.0:8000";
    extraFlags = [
      "--htpasswd-file" config.age.secrets.restic-htpasswd.path
      "--append-only"
    ];
  };

  # Reachable only via wg0; public interface stays default-deny.
  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 8000 ];

  # Pruning must run server-side because the client is append-only.
  # Runs as the `restic` user so files it rewrites stay readable by rest-server.
  systemd.services.restic-prune-nuc = {
    description = "Prune restic backups for nuc";
    serviceConfig = {
      Type = "oneshot";
      User = "restic";
      Group = "restic";
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
