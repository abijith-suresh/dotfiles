---
name: subagents
description: invoke this skill when the user asks you to use subagents
---

# Subagents

Each subagent is headless, has its own context window, cannot see the parent conversation, cannot ask the user, and cannot spawn further subagents. Give every child a self-contained prompt with paths, constraints, and the expected report.

## Pi Harness (Default)

**Harness:** `pi`
**Prompt nicknames:** "pi", "pi agent", "pi subagent"
**Best default:** Inherits the parent model and thinking level when `model` or `reasoning_effort` is omitted.

Pi can use any model shown by `pi --list-models`. Prefer `provider/model-id`; a bare model id only works when unambiguous.

**Reasoning efforts:** `off`, `minimal`, `low`, `medium`, `high`, `xhigh`, `max`. These map directly to pi thinking levels.

## Spawn and Manage

Call `subagent_spawn` with a complete `prompt`, short `name`, and optional `working_dir`, `model`, and `reasoning_effort`. At most four subagents run concurrently.

- `subagent_check({ id })`: peek without blocking.
- `subagent_list()`: list all runs.
- `subagent_wait({ ids })`: block only when results are required to proceed.
- `subagent_cancel({ ids })`: stop runs while preserving partial transcripts.
- `/subagents`: inspect or take over a run interactively.

Results return automatically. After spawning, continue useful parent work instead of immediately waiting.
