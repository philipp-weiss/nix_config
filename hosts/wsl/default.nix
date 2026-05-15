{ pkgs, unstable, ... }:
{
  wsl.enable = true;
  wsl.defaultUser = "nixos";

  programs.zsh.enable = true;
  programs.zsh.loginShellInit = "cd ~";
  users.users.nixos.shell = pkgs.zsh;

  # USB/IP support so usbipd-win on Windows can attach devices (e.g. YubiKey).
  # `usbipd attach` needs modprobe (kmod) to load vhci_hcd from the WSL kernel.
  environment.systemPackages = with pkgs; [ kmod linuxPackages.usbip usbutils ];

  # YubiKey: pcscd for PIV (used by age-plugin-yubikey) + udev rules for device access.
  services.pcscd.enable = true;
  # NixOS-WSL disables services.udev by default; re-enable so rules below get installed.
  services.udev.enable = true;
  services.udev.packages = [ pkgs.yubikey-personalization ];
  # FIDO2/U2F over hidraw — required for ssh-keygen -t ed25519-sk and SSH auth.
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", MODE="0660", GROUP="users", TAG+="uaccess"
  '';

  # Tailscale (headscale-coordinated VPN).
  # Login: tailscale up --login-server https://headscale.pweiss.org --auth-key <key>
  services.tailscale.enable = true;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit unstable; };
  home-manager.users.nixos = import ../../home/common.nix;

  system.stateVersion = "25.11";
}
