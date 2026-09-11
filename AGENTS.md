# AGENTS.md - Dotfiles Repository Guide

This is a personal, opinionated GNU Stow dotfiles repo. Agents should preserve the direct setup path and avoid rebuilding customization layers.

## Canonical Documents

- `README.md` is the user-facing overview and installation guide.
- `CONTRIBUTING.md` is the development workflow.
- `AGENTS.md` is the agent guidance and repository truth.

When behavior changes, update the matching truth document in the same change.

## Product Boundaries

- This is a personal dotfiles repo, not a dotfiles framework or public distribution.
- Keep setup direct, non-interactive, idempotent, and understandable.
- Supported platforms are WSL Ubuntu, Ubuntu, and Debian. Fedora and Arch are
  experimental; macOS is untested.
- Do not add install menus, profiles, selectors, theme switching, uninstall or
  migration frameworks, or local override UX.
- Do not add Docker, Podman, GUI apps, or desktop setup unless explicitly requested.

## Core Rules

1. `configs/` is the source of truth for deployed configuration.
2. `install.sh` is the only local setup entrypoint.
3. `boot.sh` is the only remote curl bootstrap entrypoint.
4. Do not reintroduce the stowed `dotfiles` helper.
5. Keep Catppuccin Mocha direct and explicit in checked-in config.
6. Keep scripts idempotent where possible.
7. Keep Git identity managed; this is a personal repo.

## Install Architecture

- `install/lib.sh` contains shared primitives only.
- `install/bootstrap/` contains platform bootstrap scripts.
- `install/apps/cli/` contains CLI/TUI app installers.
- `install/apps/agents/` contains coding-agent installers.
- `install/languages/` contains `mise` runtime and editor-tooling installers.
- `install/stow.sh` owns config deployment and conflict backup behavior.
- `configs/pi/.pi/agent/` contains Pi's managed settings, extensions, skills,
  themes, and locked npm manifests. `pi-setup.sh` installs dependencies after
  Stow; authentication, sessions, logs, caches, and `node_modules` remain
  runtime state.

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
