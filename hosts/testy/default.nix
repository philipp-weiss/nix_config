{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./vaultwarden.nix
    ./restic-server.nix
    ./gatus.nix
    ./headscale.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "testy";

  # agenix-rekey: master identity (YubiKey) re-encrypts secrets to this host's SSH key
  age.rekey = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILnyW+Axdl5aI0Q3mXVTgjqIH7XZpvJP0H8XiEmS5suV";
    masterIdentities = [ ../../secrets/yubikey-identity.pub ];
    storageMode = "local";
    localStorageDir = ../../secrets/rekeyed/testy;
    agePlugins = [ pkgs.age-plugin-yubikey ];
  };

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "C.UTF-8";
  console.keyMap = "de-latin1";

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
  ];


  nix.nixPath = [ "nixpkgs=flake:nixpkgs" ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAILbfosd3ekFOHG+hudDcypiT8W1pOVJHs+lHaORYCx3eAAAADnNzaDpuaXhfY29uZmln yubikey-wsl"
    # Break-glass: plain ed25519 from WSL, kept until the YubiKey path is proven.
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICZkDf2zA4TeVNjSzZXq9Jj2imPaDzsjPEmoYNhMBn2n wsl"
  ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    appendHttpConfig = ''
      add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
      add_header X-Content-Type-Options "nosniff" always;
      add_header X-Frame-Options "SAMEORIGIN" always;
      add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    '';
  };
  services.nginx.virtualHosts."vaultwarden.pweiss.org" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8222";
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "philipp.weiss@web.de";
  };

  system.autoUpgrade = {
    enable = true;
    flake = "github:philipp-weiss/nix_config#testy";
    dates = "04:00";
    allowReboot = true;
  };

  system.stateVersion = "25.05";
}
