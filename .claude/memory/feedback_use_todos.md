---
name: Default to writing todos
description: Lower the bar for creating TaskCreate todo lists so the user can follow along with multi-step work
type: feedback
originSessionId: abf371a9-91fa-48a5-95f6-c0aaa4dcf1ce
---
For any work that involves more than one step, create a TaskCreate todo list at the start, even when individual steps look small. Update task statuses as you go (in_progress → completed) so the user can see real-time progress.

**Why:** User asked on 2026-05-10 to "usually write todos so I can follow better what you are doing". They want visibility into what I'm working on, not just the final result.

**How to apply:** Bias toward more visibility, not less. Create todos when:
- The task has 2+ distinct steps
- A skill is being executed with its own multi-step workflow
- I'm running multiple tool calls in sequence to reach an outcome

Skip todos only for genuinely single-step tasks (one file read, one quick answer) or purely conversational replies.
