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

## Verification
Always execute repository validation before submitting changes:
```bash
scripts/validate.sh
```
