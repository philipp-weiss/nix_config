---
name: Don't SSH into nuc/testy yourself
description: User runs all commands on remote hosts themselves; Claude provides the commands but does not execute them via SSH
type: feedback
originSessionId: 3fcad2d6-ccc8-4dd4-82fc-3e24b75c5525
---
Never SSH into nuc or testy from WSL. Print the commands the user should run; let them execute remotely.

**Why:** User wants to control what runs on production hosts (NUC runs Home Assistant; testy hosts Vaultwarden). Even read-only commands should be the user's call.

**How to apply:** When work needs to happen on nuc/testy (rebuilds, service restarts, log checks), give the user the exact command to copy-paste. Same applies to `nix run github:nix-community/nixos-anywhere -- --flake .#<host> ...` or anything else that touches a remote machine.
