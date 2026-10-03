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

## Runtime State

Some agent CLIs persist their own state into their config file. Stowing those as symlinks writes agent state into this working tree and lets the live file silently diverge from the tracked copy. They are therefore tracked as `*.template`, excluded from Stow by `configs/.stowrc`, and copied once by `install/runtime.sh`:

| Template | Live path |
|---|---|
| `configs/pi/.pi/agent/settings.json.template` | `~/.pi/agent/settings.json` |
| `configs/codex/.codex/config.toml.template` | `~/.codex/config.toml` |

Seeding never overwrites an existing live file. After changing a template, run `install.sh --refresh-runtime` to replace the live file, keeping a `.backup`.

Keep this list minimal. Add a file here only when the owning tool is shown to write to it.

## Verification
Always execute repository validation before submitting changes:
```bash
scripts/validate.sh
```
