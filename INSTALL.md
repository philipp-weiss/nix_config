# NixOS NUC Installation

## Vorbereitung

Boot the custom ISO (includes r8125 driver and this config at `/etc/nixos-config`):
```bash
nix build .#isoImage
```

## Installation (vom eigenen PC aus)

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#nuc \
  nixos@<nuc-ip>
```

## Nach der Installation

```bash
ssh root@<nuc-ip>
git clone https://github.com/philipp-weiss/nuc.git ~/nuc
cd ~/nuc
sudo nixos-rebuild switch --flake .#nuc
```

Secrets müssen manuell erstellt werden — siehe CLAUDE.md.

## Wichtige Befehle

```bash
# Konfiguration anwenden
sudo nixos-rebuild switch --flake .#nuc

# Konfiguration testen (ohne dauerhaft zu aktivieren)
sudo nixos-rebuild test --flake .#nuc

# Flake-Inputs aktualisieren
nix flake update
sudo nixos-rebuild switch --flake .#nuc
```
