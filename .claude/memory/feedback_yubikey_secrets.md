---
name: All secrets gated by YubiKey via agenix-rekey
description: Every host (including WSL) goes through agenix-rekey; YubiKey-direct activation decryption is blocked by PIN policy
type: feedback
originSessionId: 38a049b3-2a4d-4db2-a48f-3426c8292562
---
All host secrets live in the repo encrypted only to the YubiKey master identity (`secrets/yubikey-identity.pub`). For runtime decryption, every host uses agenix-rekey to re-encrypt each secret to that host's SSH host key. The YubiKey is touched (and PIN-entered if required) only on the dev machine, during `agenix edit` and `agenix rekey -a`.

**Why:** User stated "i usually use yubikey for all secrets". We tried YubiKey-direct activation decryption on WSL (base agenix + `age-plugin-yubikey` + an identity stub at `/var/lib/agenix/yubikey-identity.txt`) and it failed: the YubiKey slot has PIN policy != Never, and the activation script has no TTY for pinentry. PIN policy is baked in at slot generation, so switching it would mean regenerating the YubiKey identity and invalidating every existing secret. Not worth it.

**How to apply:** When a new host joins this repo, give it an SSH host key (enable `services.openssh` — `openFirewall = false` is fine if you don't need inbound SSH) and wire it into agenix-rekey like nuc/bastion: `age.rekey.{hostPubkey, masterIdentities, storageMode, localStorageDir, agePlugins}` in the host module, and include `agenix-rekey.nixosModules.default` plus `agenix.nixosModules.default` in `flake.nix`. Don't try YubiKey-direct activation decryption — it cannot work non-interactively with this PIN-policy slot.
