# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commit style

Use [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): description`
Common types: `feat`, `fix`, `chore`, `docs`. Scope is usually the host (`nuc`, `bastion`) or a subsystem (`restic`, `agenix`). Example: `feat(nuc): add German keyboard layout`.

## What this repo is

A NixOS flake covering three hosts:

- **`nuc`** — Intel NUC running NixOS 25.11; primary workload is Home Assistant with a Zigbee/ZHA USB dongle. ZFS root, restic *client* backing up to `bastion`. The flake also builds a custom installer ISO bundling the r8125 2.5GbE driver and embedding this config at `/etc/nixos-config`.
- **`bastion`** — Hetzner VM running Vaultwarden and a restic REST *server* (append-only) behind nginx with ACME.
- **`wsl`** — NixOS-WSL dev machine (Windows Subsystem for Linux). Default user `nixos`. Managed with Home Manager.

The nuc and bastion hosts are coupled through restic (nuc → bastion) and share the restic encryption passphrase.

## Key commands

```bash
# Apply configuration on the local host
sudo nixos-rebuild switch --flake .#nuc      # run on the NUC
sudo nixos-rebuild switch --flake .#bastion    # run on bastion
sudo nixos-rebuild switch --flake .#wsl      # run on WSL

# Test without making it permanent
sudo nixos-rebuild test --flake .#nuc

# Update all flake inputs
nix flake update

# Update only nixpkgs-unstable (e.g. for newer claude-code)
nix flake update nixpkgs-unstable

# Build the installer ISO (for nuc)
nix build .#isoImage

# Deploy from this machine to a fresh NUC over SSH
nix run github:nix-community/nixos-anywhere -- --flake .#nuc nixos@<nuc-ip>
```

## Architecture

```
flake.nix               # Inputs (nixpkgs 25.11, nixpkgs-unstable, flake-parts, disko, agenix, agenix-rekey, nixos-wsl, home-manager); built with flake-parts (perSystem for isoImage/devShell/agenix-rekey wiring, flake.nixosConfigurations for nuc/bastion/wsl)
secrets/*.age           # Encrypted secrets (shared between hosts where applicable)
secrets/yubikey-identity.pub  # Master recipient (YubiKey) referenced from each host's age.rekey.masterIdentities
modules/
  common.nix            # Shared NixOS config imported by all hosts (nix experimental-features, allowUnfree)
home/
  common.nix            # Shared Home Manager config (zsh, starship, fzf, tmux, git, user packages)
hosts/
  nuc/
    default.nix         # Boot, networking, SSH, ZFS, Home Assistant, restic client
    disk-config.nix     # disko declarative partitioning
    hardware-configuration.nix
  bastion/
    default.nix         # Boot, networking, SSH, nginx, ACME, autoUpgrade
    vaultwarden.nix     # Vaultwarden service
    restic-server.nix   # restic REST server (append-only) + weekly prune timer
    gatus.nix           # Status page + nightly-backup freshness check
    hardware-configuration.nix
  wsl/
    default.nix         # WSL enable, defaultUser, home-manager wiring
```

Hardware-configuration files are auto-generated; do not edit by hand.

### nuc

**Storage** (`hosts/nuc/disk-config.nix`): NVMe (`/dev/nvme0n1`) → GPT → 512M vfat `/boot` + ZFS pool `rpool` (zstd compression). ZFS datasets: `root` `/`, `nix` `/nix`, `home` `/home`, `var` `/var`. Auto-scrub enabled, auto-snapshot keeps 7 daily snapshots.

**Home Assistant** (`services.home-assistant`): listens on `0.0.0.0:8123` (firewall opens 8123); extra components `zha`, `homeassistant_hardware`, `met`; `hass` user is in `dialout` for the Zigbee USB dongle. Inline automations control a Sonoff valve (`switch.sonoff_swv`) for garden watering — Mon/Wed/Sat 04:00 start in months 4–10 unless ≥3 mm rain forecast in the next 24 h, with an unconditional 06:30 stop.

**Restic backup** (client → bastion): nightly at 02:00, `/var/lib/hass` minus the SQLite recorder DB. Repository URL and password come from agenix secrets `restic-repository.age` and `restic-password.age`. Pruning runs server-side on bastion.

### wsl

**NixOS-WSL** dev machine. Default user `nixos` with zsh login shell. Imports `modules/common.nix` for shared nix settings. Home Manager (NixOS module, activated via `nixos-rebuild`) manages user environment via `home/common.nix`: zsh (with autosuggestions + syntax highlighting), starship prompt, fzf, tmux (vi keys, mouse), git config, and user packages (`claude-code` from `nixpkgs-unstable`).

### bastion

**Vaultwarden**: sets `configureNginx = true`; nginx reverse-proxy vhost is automatic at `vaultwarden.pweiss.org`.

**Restic REST server** (`hosts/bastion/restic-server.nix`): runs append-only on `127.0.0.1:8000` behind nginx (`restic.pweiss.org`). Pruning runs server-side every Sunday at 03:00 (the client cannot prune in append-only mode). ACME certificates cover `vaultwarden.pweiss.org`, `restic.pweiss.org`, and `status.pweiss.org`.

**Status monitoring** (`hosts/bastion/gatus.nix`): gatus on `127.0.0.1:8080` behind a basic-auth-protected nginx vhost at `status.pweiss.org`. Probes vaultwarden and the restic REST server every 5 min. A `restic-backup-check` systemd timer runs daily at 02:30 (as the `restic` user), stats `/var/lib/restic/nuc/snapshots` for files modified in the last 25h, and pushes success/failure to a gatus external endpoint (`cron_nightly-backup`); if no push arrives within 25h, gatus flips that endpoint to DOWN.

## agenix + agenix-rekey

Source secrets in `secrets/*.age` are encrypted **only** to a single master
identity (the YubiKey, recipient at `secrets/yubikey-identity.pub` and wired
into each host via `age.rekey.masterIdentities`). On build, agenix-rekey
re-encrypts each secret to the host's SSH key and writes the result to
`secrets/rekeyed/<host>/`. Those rekeyed files are committed so unattended
`system.autoUpgrade` can build without the YubiKey present.

Use the `agenix` CLI from the dev shell (it's the agenix-rekey wrapper, not
upstream agenix):

```bash
nix develop                              # drops you in a shell with `agenix`
agenix edit secrets/restic-password.age  # YubiKey touch required
agenix rekey -a                          # re-encrypt all secrets for all hosts
```

Then `git add secrets/rekeyed/ && git commit`.

Per-host rekey config lives in each host's NixOS module (`age.rekey.*`):
`hostPubkey` (the host's SSH ed25519 pub), `masterIdentities` (path to
`secrets/yubikey-identity.pub`), `storageMode = "local"`,
`localStorageDir = ../../secrets/rekeyed/<host>`.

Secrets are declared with `age.secrets.X.rekeyFile = ...` (not `.file`).

## Auto-upgrade

Both hosts run `system.autoUpgrade` daily at 04:00 with `allowReboot = true`, pulling `github:philipp-weiss/nix_config#<hostname>`. Pushed commits roll out automatically.

## Notable constraints

- `networking.hostId` (`fdd62ac8`) is required by ZFS on nuc and must stay in sync with the pool.
- SSH password auth is disabled on both hosts; only the listed ed25519 keys can log in as root.
- The r8125 driver is loaded both in the ISO and in the installed nuc system (`boot.extraModulePackages`).
- `nixpkgs-unstable` is used only for packages that need bleeding-edge versions (currently `claude-code`). It is configured with `allowUnfree = true` separately from the main nixpkgs. Pass `unstable` via `specialArgs`/`extraSpecialArgs` to use it in modules.
