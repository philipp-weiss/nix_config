{ ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Always re-resolve github: flake refs on build — no stale cache after a push.
  nix.settings.tarball-ttl = 0;
  nixpkgs.config.allowUnfree = true;
}
