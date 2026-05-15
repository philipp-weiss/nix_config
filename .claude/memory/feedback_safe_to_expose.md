---
name: Only commit safe-to-expose content
description: Memory and repo files are pushed to the public GitHub repo philipp-weiss/nix_config, so treat everything written there as public
type: feedback
originSessionId: 19ae9b7e-4368-4a05-9e7c-8582951a886a
---
Only add content to memory and the nix_config repo that is safe to expose publicly.

**Why:** the memory directory at `~/.claude/projects/-home-nixos-nix-config/memory/` is backed by `nix_config/.claude/memory/`, which is committed and pushed to `github:philipp-weiss/nix_config` — a public repo (it's used as a flake ref for unattended autoUpgrade, which requires public access). Anything written to memory or the repo is world-readable.

**How to apply:**
- Don't write IPs, tokens, private keys, internal-only hostnames, or anything that combines otherwise-public facts into a useful target profile (e.g. "this IP runs services X, Y, Z").
- Public domain names that already appear in nix files (e.g. `*.pweiss.org` vhost names) are fine — they're already in the repo.
- If a fact is genuinely useful for future sessions but sensitive, ask the user where to put it instead, or omit the sensitive detail and keep the structural fact (e.g. "wildcard DNS exists" rather than "wildcard DNS points at <ip>").
- Apply the same caution to .nix files: comments, hostnames in URLs, and config values all get pushed.
