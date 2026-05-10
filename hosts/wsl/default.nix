{ ... }:
{
  wsl.enable = true;
  wsl.defaultUser = "nixos";

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.nixos = import ../../home/common.nix;

  system.stateVersion = "25.11";
}
