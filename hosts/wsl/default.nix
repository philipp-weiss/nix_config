{ pkgs, ... }:
{
  wsl.enable = true;
  wsl.defaultUser = "nixos";

  programs.zsh.enable = true;
  programs.zsh.loginShellInit = "cd ~";
  users.users.nixos.shell = pkgs.zsh;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.nixos = import ../../home/common.nix;

  system.stateVersion = "25.11";
}
