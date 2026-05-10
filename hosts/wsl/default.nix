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
  services.udev.packages = [ pkgs.yubikey-personalization ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit unstable; };
  home-manager.users.nixos = import ../../home/common.nix;

  system.stateVersion = "25.11";
}
