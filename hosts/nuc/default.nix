{ config, pkgs, ... }:
{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ./home-assistant.nix
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
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAILbfosd3ekFOHG+hudDcypiT8W1pOVJHs+lHaORYCx3eAAAADnNzaDpuaXhfY29uZmln yubikey-wsl"
  ];

  # SSH
  # SSH only via the WG mesh; recovery if WG breaks is physical console access.
  services.openssh = {
    enable = true;
    openFirewall = false;
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

  # WireGuard (spoke): dials the bastion hub. All inter-peer traffic hairpins
  # through bastion. Peer pubkeys live in nix; only this host's private key
  # is encrypted via agenix.
  age.secrets.wg-nuc-private.rekeyFile = ../../secrets/wg-nuc.age;

  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.42.0.2/24" ];
    privateKeyFile = config.age.secrets.wg-nuc-private.path;
    mtu = 1280;
    peers = [
      {
        publicKey = "fV8gh4dAemQPTkaY6ilyeB+wniPHZAHtE+6bv/Kf41U=";
        allowedIPs = [ "10.42.0.0/24" ];
        endpoint = "wireguard.pweiss.org:51820";
        persistentKeepalive = 25;
      }
    ];
  };

  networking.extraHosts = ''
    10.42.0.1 bastion
    10.42.0.2 nuc
    10.42.0.3 wsl
  '';

  # SSH reachable only via wg0; LAN/public stays default-deny.
  # (Home Assistant adds its own 8123 rule in home-assistant.nix.)
  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 22 ];

  # agenix-rekey: master identity (YubiKey) re-encrypts secrets to this host's SSH key
  age.rekey = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGdwE7xHYwdbM2IETm3fIH+rxrVeY24Ofnc49Qb/siZb";
    masterIdentities = [ ../../secrets/yubikey-identity.pub ];
    storageMode = "local";
    localStorageDir = ../../secrets/rekeyed/nuc;
    agePlugins = [ pkgs.age-plugin-yubikey ];
  };

  # Restic backup of Home Assistant to bastion (append-only, prune runs server-side).
  # Freshness monitoring lives on bastion (filesystem-based check pushes to gatus).
  age.secrets.restic-rest-password.rekeyFile = ../../secrets/restic-rest-password.age;
  age.secrets.restic-password.rekeyFile = ../../secrets/restic-password.age;

  services.restic.backups.home-assistant = {
    repositoryFile = "/run/restic-backups-home-assistant/repo-url";
    passwordFile = config.age.secrets.restic-password.path;
    initialize = true;
    # Templating the URL here keeps only the basic-auth password in agenix; the
    # address lives in nix and can be changed without a YubiKey touch.
    backupPrepareCommand = ''
      set -e
      umask 077
      printf 'rest:http://nuc:%s@bastion:8000/nuc/' \
        "$(cat ${config.age.secrets.restic-rest-password.path})" \
        > /run/restic-backups-home-assistant/repo-url
    '';
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
