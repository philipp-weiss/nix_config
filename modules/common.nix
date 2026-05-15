{ ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Always re-resolve github: flake refs on build — no stale cache after a push.
  nix.settings.tarball-ttl = 0;
  nixpkgs.config.allowUnfree = true;

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "C.UTF-8";
  console.keyMap = "de-latin1";

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # WireGuard peer names — same on every host on the mesh.
  networking.extraHosts = ''
    10.42.0.1 bastion
    10.42.0.2 nuc
    10.42.0.3 wsl
  '';
}
