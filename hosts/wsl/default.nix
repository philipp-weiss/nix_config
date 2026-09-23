{ config, pkgs, unstable, ... }:
{
  wsl.enable = true;
  wsl.defaultUser = "nixos";
  networking.hostName = "wsl";
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
    # VS Code Remote-WSL shells out to wget to fetch its server tarball into
    # ~/.vscode-server and aborts with "'wget' not installed" without it.
    wget
  ];

  # That server ships its own dynamically-linked node, which looks for the
  # glibc loader at /lib64/ld-linux-x86-64.so.2 — on NixOS that path is a stub
  # that only prints an error. nix-ld puts a real loader there so foreign
  # binaries like the VS Code server can run.
  programs.nix-ld.enable = true;

  # sshd is enabled solely so NixOS provisions an SSH host key for
  # agenix-rekey to target. We never want inbound SSH on WSL itself.
  services.openssh = {
    enable = true;
    openFirewall = false;
  };

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMKbqoE+0wANUEFWl41DIrO0yvQdsu1BUzQaDubdhaJq";

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
        # Without this the peer unit is a oneshot that resolves the endpoint
        # once at boot; if DNS isn't up yet ("Name or service not known") it
        # fails for good and the host never dials the hub. The refresh unit
        # retries after 10 s and re-resolves every 5 min.
        dynamicEndpointRefreshSeconds = 300;
        dynamicEndpointRefreshRestartSeconds = 10;
      }
    ];
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit unstable; };
  home-manager.users.nixos = import ../../home/common.nix;

  system.stateVersion = "25.11";
}
