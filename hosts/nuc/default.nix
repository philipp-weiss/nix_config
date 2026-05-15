{ config, pkgs, ... }:
{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  # Realtek R8125 2.5GbE Treiber
  boot.extraModulePackages = [ config.boot.kernelPackages.r8125 ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Netzwerk
  networking.hostName = "nuc";
  networking.hostId = "fdd62ac8"; # Pflicht für ZFS
  networking.useDHCP = true;

  # Zeitzone & Lokalisierung
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";
  console.keyMap = "de-latin1";

  # Benutzer
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICZkDf2zA4TeVNjSzZXq9Jj2imPaDzsjPEmoYNhMBn2n wsl"
  ];

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # Grundlegende Pakete
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    htop
  ];

  # ZFS
  boot.supportedFilesystems = [ "zfs" ];
  services.zfs.autoScrub.enable = true;
  services.zfs.autoSnapshot = {
    enable = true;
    frequent = 0;
    hourly = 0;
    daily = 7;
    weekly = 0;
    monthly = 0;
  };

  # Firewall
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 8123 ];

  # Home Assistant USB Zigbee Dongle Zugriff
  users.users.hass.extraGroups = [ "dialout" ];

  # Home Assistant
  services.home-assistant = {
    enable = true;
    extraComponents = [
      "zha"
      "homeassistant_hardware"
      "met"
    ];
    config = {
      homeassistant = {
        name = "Home";
        time_zone = "Europe/Berlin";
        unit_system = "metric";
        currency = "EUR";
        country = "DE";
      };
      default_config = {};
      http.server_host = "0.0.0.0";
      rest = [
        {
          resource_template = "https://api.open-meteo.com/v1/forecast?latitude={{ state_attr('zone.home', 'latitude') }}&longitude={{ state_attr('zone.home', 'longitude') }}&past_hours=24&forecast_hours=24&hourly=precipitation&timezone=Europe%2FBerlin";
          scan_interval = 1800;
          sensor = [
            {
              name = "rain_past_24h";
              value_template = "{{ value_json.hourly.precipitation[:24] | sum }}";
              unit_of_measurement = "mm";
            }
            {
              name = "rain_forecast_24h";
              value_template = "{{ value_json.hourly.precipitation[24:48] | sum }}";
              unit_of_measurement = "mm";
            }
          ];
        }
      ];
      automation = [
        {
          id = "garden_watering_start";
          alias = "Garden watering — start";
          description = "Open valve Mon/Wed/Sat at 04:00 during growing season, unless ≥3 mm rain fell in last 24h or is forecast for next 24h (Open-Meteo)";
          triggers = [
            { trigger = "time"; at = "04:00:00"; }
          ];
          conditions = [
            { condition = "time"; weekday = [ "mon" "wed" "sat" ]; }
            { condition = "template"; value_template = "{{ 4 <= now().month <= 10 }}"; }
            { condition = "template"; value_template = "{{ states('sensor.rain_past_24h') | float(99) < 3 }}"; }
            { condition = "template"; value_template = "{{ states('sensor.rain_forecast_24h') | float(99) < 3 }}"; }
          ];
          actions = [
            { action = "switch.turn_on"; target.entity_id = "switch.sonoff_swv"; }
          ];
          mode = "single";
        }
        {
          id = "garden_watering_stop";
          alias = "Garden watering — stop (safety)";
          description = "Always close valve at 06:30, regardless of weekday/season";
          triggers = [
            { trigger = "time"; at = "06:30:00"; }
          ];
          actions = [
            { action = "switch.turn_off"; target.entity_id = "switch.sonoff_swv"; }
          ];
          mode = "single";
        }
      ];
    };
  };

  # agenix-rekey: master identity (YubiKey) re-encrypts secrets to this host's SSH key
  age.rekey = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGdwE7xHYwdbM2IETm3fIH+rxrVeY24Ofnc49Qb/siZb";
    masterIdentities = [ ../../secrets/yubikey-identity.pub ];
    storageMode = "local";
    localStorageDir = ../../secrets/rekeyed/nuc;
    agePlugins = [ pkgs.age-plugin-yubikey ];
  };

  # Restic backup of Home Assistant to testy (append-only, prune runs server-side).
  # Freshness monitoring lives on testy (filesystem-based check pushes to gatus).
  age.secrets.restic-repository.rekeyFile = ../../secrets/restic-repository.age;
  age.secrets.restic-password.rekeyFile = ../../secrets/restic-password.age;

  services.restic.backups.home-assistant = {
    repositoryFile = config.age.secrets.restic-repository.path;
    passwordFile = config.age.secrets.restic-password.path;
    initialize = true;
    paths = [ "/var/lib/hass" ];
    exclude = [
      "/var/lib/hass/home-assistant_v2.db"
      "/var/lib/hass/home-assistant_v2.db-shm"
      "/var/lib/hass/home-assistant_v2.db-wal"
    ];
    timerConfig = {
      OnCalendar = "02:00";
      Persistent = true;
    };
  };


  nix.nixPath = [ "nixpkgs=flake:nixpkgs" ];

  # Nix Garbage Collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  system.autoUpgrade = {
    enable = true;
    flake = "github:philipp-weiss/nix_config#nuc";
    dates = "04:00";
    allowReboot = true;
  };

  system.stateVersion = "25.05";
}
