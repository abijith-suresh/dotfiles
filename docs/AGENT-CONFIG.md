# Agent configuration

The coding agents share the same personal working agreement while retaining
their native configuration formats.

## Shared instructions

The policy is installed in the global locations each agent reads:

- Claude: ~/.claude/CLAUDE.md
- Codex: ~/.codex/AGENTS.md
- OpenCode: ~/.config/opencode/AGENTS.md
- Pi: ~/.pi/agent/AGENTS.md
- Pi and other Agent Skills-compatible tools: ~/.agents/skills/dotfiles/
- Antigravity: ~/.gemini/config/skills/dotfiles/

The copies contain the same short working agreement. They cover repository
guidance, preservation of unrelated changes, temporary test state, validation,
credential hygiene, and explicit intent for destructive actions.

## Native settings

Each agent keeps its own settings file because the formats and capabilities
differ:

| Agent | Settings | Shared resources |
| --- | --- | --- |
| Claude | .claude/settings.json | .claude/CLAUDE.md |
| Codex | .codex/config.toml | .codex/AGENTS.md |
| OpenCode | .config/opencode/opencode.jsonc | .config/opencode/AGENTS.md |
| Pi | .pi/agent/settings.json | .pi/agent/AGENTS.md and Agent Skills |
| Antigravity | .gemini/antigravity-cli/settings.json | .gemini/config/skills |

Models remain provider-specific. Approval and sandbox settings should be
changed in a later focused review after comparing the behavior of each CLI.
