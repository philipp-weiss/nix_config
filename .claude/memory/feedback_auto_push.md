---
name: Auto-push after committing
description: In this repo, push immediately after creating a commit — no separate confirm step
type: feedback
originSessionId: abf371a9-91fa-48a5-95f6-c0aaa4dcf1ce
---
After creating a commit the user asked for, run `git push` immediately as part of the same flow. Don't pause to ask "want me to push?".

**Why:** User explicitly opted into auto-push when asked about default policy on 2026-05-10. They found the extra confirm step unnecessary friction in this repo's direct-to-main workflow.

**How to apply:** Applies to ordinary commits on `main` (the normal flow here). Still confirm before anything destructive or unusual: `git push --force`, pushing to a branch the user didn't explicitly name, pushing commits the user didn't ask you to make, or any push that would overwrite remote history.
