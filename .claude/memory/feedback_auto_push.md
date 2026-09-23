---
name: Never commit unless asked; auto-push only requested commits
description: Never run git commit unless the user explicitly asked; push immediately only after a commit they requested
type: feedback
originSessionId: abf371a9-91fa-48a5-95f6-c0aaa4dcf1ce
modified: 2026-09-23T11:36:54.335Z
---

Never run `git commit` in this repo unless the user explicitly asked for a commit. Writing code, verifying it, or finishing a task is **not** permission to commit it. Default to leaving the change in the working tree and saying so.

Once the user *has* asked for a commit, push immediately as part of the same flow — don't pause to ask "want me to push?".

**Why:** The user opted into auto-push on 2026-05-10 to remove friction in this direct-to-main workflow. On 2026-09-23 Claude answered a *question* ("I want to use VS Code instead, it has a Neovim plugin?") by writing files, committing to `main`, and pushing to the public repo — none of it requested. The user objected. The earlier wording did already cover the case ("confirm before pushing commits the user didn't ask you to make") but framed it as a *push* exception, which left the commit step reading as automatic. The user asked to tighten it so the commit itself is gated.

**How to apply:** Finish work by reporting what changed and leaving it uncommitted; ask before committing. After a commit the user asked for, run `git push` immediately (ordinary commits on `main` — the normal flow here). Still confirm separately before anything destructive or unusual: `git push --force`, pushing to a branch the user didn't name, or any push that would overwrite remote history.

**Standing exception:** edits to `.claude/memory/*.md` carry pre-approved commit+push in the same turn — see [[feedback_commit_memory]]. That exception is scoped to memory files only; it does not extend to config or code changes.
