---
name: Stage files before nix eval/build
description: Always `git add` new or modified files before running `nix eval`, `nix build`, or `nix flake check` against the flake
type: feedback
originSessionId: e7fb4344-f6e9-4013-946c-07d99d2fa092
---
Always `git add` newly created or modified `.nix` files before running any `nix eval`, `nix build`, or `nix flake check` invocation against this flake.

**Why:** Flake evaluation reads from a git-tree-derived source store path. Untracked files are invisible to that path even on a dirty tree, producing confusing `error: path '/nix/store/.../foo.nix' does not exist` failures and wasting a round-trip. Staging the file makes it visible without requiring a commit.

**How to apply:** As soon as a `.nix` file is created or modified, stage it (`git add path`) before any validation step. Especially relevant when creating new host modules or new files imported from existing ones.
