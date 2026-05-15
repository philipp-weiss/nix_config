{ config, pkgs, unstable, ... }:
{
  wsl.enable = true;
  wsl.defaultUser = "nixos";
  # WSL otherwise overwrites /etc/hosts at boot, which would clobber the
  # WireGuard peer entries below.
  wsl.wslConf.network.generateHosts = false;

  programs.zsh.enable = true;
  programs.zsh.loginShellInit = "cd ~";
  users.users.nixos.shell = pkgs.zsh;

  # USB/IP support so usbipd-win on Windows can attach devices (e.g. YubiKey).
  # `usbipd attach` needs modprobe (kmod) to load vhci_hcd from the WSL kernel.
  environment.systemPackages = with pkgs; [
    kmod
    linuxPackages.usbip
    usbutils
  ];

  # sshd is enabled solely so NixOS provisions an SSH host key for
  # agenix-rekey to target. We never want inbound SSH on WSL itself.
  services.openssh = {
    enable = true;
    openFirewall = false;
  };

  # agenix-rekey wiring (same pattern as nuc/bastion).
  age.rekey = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMKbqoE+0wANUEFWl41DIrO0yvQdsu1BUzQaDubdhaJq";
    masterIdentities = [ ../../secrets/yubikey-identity.pub ];
    storageMode = "local";
    localStorageDir = ../../secrets/rekeyed/wsl;
    agePlugins = [ pkgs.age-plugin-yubikey ];
  };

  # YubiKey: pcscd for PIV (used by age-plugin-yubikey) + udev rules for device access.
  services.pcscd.enable = true;
  # NixOS-WSL disables services.udev by default; re-enable so rules below get installed.
  services.udev.enable = true;
  services.udev.packages = [ pkgs.yubikey-personalization ];
  # FIDO2/U2F over hidraw — required for ssh-keygen -t ed25519-sk and SSH auth.
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", MODE="0660", GROUP="users", TAG+="uaccess"
  '';

  # WireGuard (spoke): dials the bastion hub. WSL2 kernel ships the wireguard
  # module, so plain `networking.wireguard.interfaces` works without wg-quick.
  age.secrets.wg-wsl-private.rekeyFile = ../../secrets/wg-wsl.age;

  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.42.0.3/24" ];
    privateKeyFile = config.age.secrets.wg-wsl-private.path;
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

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit unstable; };
  home-manager.users.nixos = import ../../home/common.nix;

  system.stateVersion = "25.11";
}
