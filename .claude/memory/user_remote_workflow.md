---
name: Edits on WSL, applies on nuc/testy via SSH
description: User edits this repo from the WSL host and applies changes to nuc/testy by SSHing into them
type: user
originSessionId: abf371a9-91fa-48a5-95f6-c0aaa4dcf1ce
---
The user works in this repo from the WSL host (the cwd Claude is running in). To apply changes on `nuc` or `testy`, they SSH into the target host and run `nixos-rebuild switch --flake github:philipp-weiss/nix_config#<host>` (or push first then run on the host).

**Implication:** When suggesting an apply step for `nuc` or `testy`, don't run `sudo nixos-rebuild switch --flake .#nuc` locally — it would try to build the nuc config on WSL. Instead suggest either (a) push the commit and SSH to the host, or (b) `nixos-rebuild --target-host` if appropriate. For the `wsl` config itself, local `nixos-rebuild switch --flake .#wsl` is correct.

The hosts also auto-upgrade daily at 04:00 from `github:philipp-weiss/nix_config#<host>`, so for non-urgent changes, pushing to `main` is enough — the host will pick it up overnight.
