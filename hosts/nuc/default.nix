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
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHgCqkVI/LR3FFI9z1JLnQylOsteuCg3fP2UXAf/Bnzu philipp.weiss@web.de"
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
      automation = [
        {
          id = "garden_watering_start";
          alias = "Garden watering — start";
          description = "Open valve Mon/Wed/Sat at 04:00 during growing season, unless ≥3 mm rain forecast in next 24h";
          triggers = [
            { trigger = "time"; at = "04:00:00"; }
          ];
          conditions = [
            { condition = "time"; weekday = [ "mon" "wed" "sat" ]; }
            { condition = "template"; value_template = "{{ 4 <= now().month <= 10 }}"; }
          ];
          actions = [
            {
              action = "weather.get_forecasts";
              data.type = "hourly";
              target.entity_id = "weather.forecast_home";
              response_variable = "fcst";
            }
            {
              condition = "template";
              value_template = "{{ (fcst['weather.forecast_home'].forecast[:24] | sum(attribute='precipitation')) < 3 }}";
            }
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

  # Restic backup of Home Assistant to testy (append-only, prune runs server-side)
  age.secrets.restic-repository.file = ../../secrets/restic-repository.age;
  age.secrets.restic-password.file = ../../secrets/restic-password.age;

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

  # Flakes aktivieren
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.nixPath = [ "nixpkgs=flake:nixpkgs" ];

  # Nix Garbage Collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  system.autoUpgrade = {
    enable = true;
    flake = "github:philipp-weiss/nix-config#nuc";
    dates = "04:00";
    allowReboot = true;
  };

  system.stateVersion = "25.05";
}
