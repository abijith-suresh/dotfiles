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
4. Theme is Catppuccin Mocha everywhere. Keep palette definitions direct in configs; Pi's theme ships in [Tangent](https://github.com/abijith-suresh/tangent) and is not managed here. Neovim may fall back to Catppuccin Latte on light backgrounds.
5. External installer changes must reference official documentation in a script comment and in the record's `docs=` field.
6. Never pin a default model, provider, or default model arguments in checked-in config. Model catalogues churn constantly and pinning them forces a dotfiles change per release.

## Installer organization

`install/manifest.bash` is the app inventory: one `register` record per app; `install.sh` only iterates it. Records run in the order they appear, grouped by phase: foundation, cli, languages, agents, post-stow (Tangent, after Stow). Plain package installs are records only (`source=pkg`); a script under `install/apps/` or `install/languages/` exists only when the install needs real logic and must be referenced by some record. Record the official documentation URL in `docs=` for scripted installs.

Stow ignore rules live in `configs/.stowrc` and are applied by Stow itself; `install/stow.sh` derives deployable entries from Stow's own plan.

## Runtime state

Agent CLIs are installed only; this repository does not manage their configuration. Each CLI reads and writes its own native state directory, including credentials, sessions, logs, caches, and project trust. Do not add agent settings packages to `configs/` or stow them.

After installing Pi, install Tangent through Pi's native `pi install` command using the tagged source in `install/apps/agents/tangent.sh`. Pi registers the package without a custom merge layer. Fresh Pi installs start on Pi's default theme, so Catppuccin Mocha is not selected automatically. Keep Pi extensions, themes, and their development dependencies in Tangent, not this repository.

Keep agent state in native directories. Use XDG paths for tools that already support them, without requiring credential moves. Fresh installs must not configure MCP servers. Railway installation is CLI-only.
