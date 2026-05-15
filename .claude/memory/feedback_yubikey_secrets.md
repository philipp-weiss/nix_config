---
name: All secrets gated by YubiKey
description: User wants every host's secrets behind the YubiKey, including WSL which lacks an SSH host key
type: feedback
originSessionId: 38a049b3-2a4d-4db2-a48f-3426c8292562
---
All host secrets must stay behind the YubiKey age identity. For nuc and bastion, that means agenix-rekey with each host's SSH pubkey as the rekey target (existing pattern). For WSL — which has no SSH host key and is excluded from agenix-rekey — use the base `agenix.nixosModules.default` with `age.identityPaths` pointing at a YubiKey identity stub, so activation decrypts via age-plugin-yubikey directly.

**Why:** User stated explicitly: "i usually use yubikey for all secrets". They rejected plain-file or non-YubiKey workarounds for WSL.

**How to apply:** When adding a new secret to WSL, never propose a plain file or alternative key source. Use `age.secrets.X.file = ../../secrets/X.age` with the YubiKey identity stub configured under `age.identityPaths`. Tradeoff the user has accepted: WSL rebuilds and reboots require the YubiKey attached + touch.
