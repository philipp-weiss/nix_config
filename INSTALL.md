# NixOS NUC Installation

## Preparation

Build the custom ISO (includes the r8125 driver and this config at `/etc/nixos-config`):
```bash
nix build .#isoImage
```
Flash it to a USB stick and boot the NUC from it.

## Installation (from your own PC)

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#nuc \
  nixos@<nuc-ip>
```

Secrets must be created manually — see CLAUDE.md.

## Common commands

```bash
# Apply configuration
sudo nixos-rebuild switch --flake .#nuc

# Update flake inputs
nix flake update
sudo nixos-rebuild switch --flake .#nuc
```
