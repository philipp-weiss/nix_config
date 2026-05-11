# NixOS NUC Installation

## Vorbereitung

Build the custom ISO (includes the r8125 driver and this config at `/etc/nixos-config`):
```bash
nix build .#isoImage
```
Flash it to a USB stick and boot the NUC from it.

## Installation (vom eigenen PC aus)

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#nuc \
  nixos@<nuc-ip>
```

Secrets müssen manuell erstellt werden — siehe CLAUDE.md.

## Wichtige Befehle

```bash
# Konfiguration anwenden
sudo nixos-rebuild switch --flake .#nuc

# Flake-Inputs aktualisieren
nix flake update
sudo nixos-rebuild switch --flake .#nuc
```
