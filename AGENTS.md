# AGENTS.md - Dotfiles Repository Guide

This is a personal, opinionated GNU Stow dotfiles repo. Agents should preserve the direct setup path and avoid rebuilding customization layers.

## Document Ownership

- `README.md` is user-facing only.
- `docs/CONTEXT.md` is product truth: goals, non-goals, constraints, and success criteria.
- `docs/ARCHITECTURE.md` is technical truth.
- `docs/CONTRIBUTING.md` is development workflow.
- `AGENTS.md` is agent behavior and truth maintenance rules.

When behavior changes, update the matching truth document in the same change.

## Core Rules

1. `configs/` is the source of truth for deployed configuration.
2. `install.sh` is the only local setup entrypoint.
3. `boot.sh` is the only remote curl bootstrap entrypoint.
4. Do not reintroduce the stowed `dotfiles` helper.
5. Do not add menus, profiles, install selectors, uninstall framework, migration framework, theme switching, or local override UX.
6. Keep Catppuccin Mocha direct and explicit in checked-in config.
7. Keep scripts idempotent where possible.
8. Keep Git identity managed; this is a personal repo.
9. Do not install Docker or Podman unless explicitly requested.
10. Do not add GUI app or desktop setup until explicitly requested.

## Install Architecture

- `install/lib.sh` contains shared primitives only.
- `install/bootstrap/` contains platform bootstrap scripts.
- `install/apps/cli/` contains CLI/TUI app installers.
- `install/apps/agents/` contains coding-agent installers.
- `install/languages/` contains `mise` runtime and editor-tooling installers.
- `install/stow.sh` owns config deployment and conflict backup behavior.

Script execution order is defined in `install.sh` arrays. Do not rely on filename sorting.

## Source Policy

Before changing installer commands for external tools, verify current official or canonical docs. Add or update a short source-policy comment in the affected script.

For OpenAI Codex behavior or config, use official OpenAI Codex docs/manual as the source of truth.

## Stow Rules

- Use `install/stow.sh` for deployment behavior.
- Keep `STOW_PACKAGES` explicit.
- Every `configs/<package>` directory must be listed in `STOW_PACKAGES`.
- Every package listed in `STOW_PACKAGES` must exist.
- Use `--no-folding`.
- Back up unmanaged conflicts before stowing.
- Runtime/cache/auth files must not be managed.

## Validation

Before finishing substantial changes, run:

```bash
scripts/validate.sh
```

If validation cannot be run, say why.
