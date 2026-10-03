# AGENTS.md - Dotfiles Repository Guide

Personal GNU Stow dotfiles for WSL Ubuntu, Ubuntu, and Debian. Keep setup direct, non-interactive, and idempotent.

## Negative Constraints & Boundaries
- Do NOT add install menus, interactive prompts, profiles, theme switchers, or migration/uninstall frameworks.
- Do NOT add Docker, Podman, GUI apps, or desktop environments unless explicitly requested.
- Do NOT commit runtime state, credentials, auth tokens, session DBs, or host-specific project trust (e.g. Codex `projects."<path>"`).

## Repository Invariants
1. `configs/` is the sole source of truth for stowed configurations.
2. `install.sh` is the only local entrypoint; `boot.sh` is the only remote bootstrap.
3. Every package in `configs/<name>` must be registered in `STOW_PACKAGES` in `install/stow.sh` and deploy cleanly via `stow --no-folding`.
4. Theme is Catppuccin Mocha everywhere. Keep palette definitions direct in configs.
5. External installer changes must reference official documentation in a script comment.
6. Never pin a default model, provider, or default model arguments in checked-in config. Model catalogues churn constantly and pinning them forces a dotfiles change per release.

## Runtime state

Pi and Codex settings use their native paths and are stowed directly on fresh installs:

| Configuration | Live path |
|---|---|
| `configs/pi/.pi/agent/settings.json` | `~/.pi/agent/settings.json` |
| `configs/codex/.codex/config.toml` | `~/.codex/config.toml` |

Tool writes through these symlinks may dirty the checkout. Review those changes and never commit credentials, model defaults, runtime state, or project trust. Stow excludes auth files, sessions, logs, caches, and backups.

If either settings path already exists and does not resolve to its tracked source, the installer keeps it active and reports it. Other files in that package still deploy. This preserves owned settings and trust when a CLI replaces its symlink. A blocking parent symlink fails deployment without moving those settings. Do not add a seeding, refresh, merge, or migration layer.

Keep agent state in native directories. Use XDG paths for tools that already support them, without requiring credential moves. Fresh installs must not configure MCP servers. Railway installation is CLI-only.

## Verification
Always execute repository validation before submitting changes:
```bash
scripts/validate.sh
```
