---
name: subagents
description: Use Pi subagents when the user asks for delegated or parallel tasks.
---

# Subagents

Each child is a one-shot, headless Pi SDK session with its own context. It cannot see the parent conversation, ask the user or spawn more subagents. Give it a complete prompt with paths, constraints and the expected report. At most four children run at once. Identical active tasks are rejected, including concurrent spawn requests.

Call `subagent_spawn` with `prompt`, `name` and an optional `mode`:

- `background`, the default, returns an id once the child session starts. Keep doing useful parent work. Its result arrives automatically when the parent settles, or immediately if the parent is already idle.
- `foreground` waits and returns the result in the same call. Use this when the parent cannot proceed without the child's work.

Optional `working_dir` selects the child's directory. Same-directory children inherit the parent's project trust decision. Other directories load project resources only if Pi's trust store trusts them. Optional `model` accepts `provider/model-id` or an unambiguous model id. Omit it and `reasoning_effort` to inherit the parent model and thinking level.

Use these tools when needed:

- `subagent_wait({ ids })` collects results together. Successful collection suppresses pending automatic delivery. Aborting a wait leaves the children running and restores automatic delivery, including results that settled during the wait.
- `subagent_check({ id })` shows status and a bounded output preview.
- `subagent_list()` lists tracked tasks.
- `subagent_cancel({ ids })` aborts active work and reports cancellation. It does not also send an automatic completion message. Partial session transcripts remain on disk.

Do not repeatedly poll status or create duplicate tasks. Background errors also arrive automatically. Settled children release their SDK sessions, and shutting down the parent closes active children without sending late results. Background work needs a running parent process; it does not survive Pi exiting.

There is no subagent dashboard, transcript viewer or takeover command. `/btw <question>` starts a user aside in the TUI and displays its answer as a session entry without adding it to the main model's context.
