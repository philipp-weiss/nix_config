---
name: Skip nixos-rebuild test, go straight to switch
description: User prefers `nixos-rebuild switch` directly — don't suggest a `test` step first
type: feedback
originSessionId: abf371a9-91fa-48a5-95f6-c0aaa4dcf1ce
---
When applying NixOS changes, suggest `sudo nixos-rebuild switch --flake .#<host>` directly. Don't preface with `nixos-rebuild test` as a safety step.

**Why:** User explicitly said "straight switch" on 2026-05-10 when asked about preferred flow. They're comfortable rolling back via the bootloader generation if a switch breaks something.

**How to apply:** Default to `switch`. Only suggest `test` first if the change is unusually risky (e.g. boot/networking/ZFS changes that could prevent the system from coming back up cleanly), and even then, frame it as a question rather than a default.
