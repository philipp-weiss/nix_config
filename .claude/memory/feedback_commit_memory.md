---
name: Auto-commit memory changes
description: After writing or updating any file in .claude/memory/, commit and push immediately
type: feedback
---

Whenever I add, update, or remove a file under `.claude/memory/`, commit and push the change in the same turn. Don't leave memory files as dangling uncommitted changes in the working tree.

**Why:** Memory now lives in the repo via a `mkOutOfStoreSymlink` (see `home/common.nix`). The whole point of moving it into the repo is reproducibility across machines/reinstalls — that only works if changes are actually committed. User explicitly opted in on 2026-05-10.

**How to apply:** After any Write/Edit on `.claude/memory/*.md` (including `MEMORY.md`), run `git add .claude/memory/<file> [MEMORY.md] && git commit -m "chore(memory): <verb> <name>" && git push`. Use a brief conventional-commit message — `add`, `update`, or `remove` as the verb. Combine with any other related changes if they're part of the same logical edit (e.g. saving a memory immediately after committing a feature fix can ride along).
