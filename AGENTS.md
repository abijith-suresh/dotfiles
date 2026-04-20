# AGENTS.md - Dotfiles Repository Guide

This repository is a GNU Stow-based dotfiles system with a single Catppuccin Mocha theme and a modular install architecture.

## Core rules

1. **`configs/` is the source of truth for deployed configuration**
   - If a file should exist on the machine via Stow, its authoritative source lives in `configs/`.

2. **Theme config is now direct and hand-maintained**
   - Do not rebuild a multi-theme layer.
   - Prefer explicit Catppuccin Mocha config checked into `configs/`.
   - If a tool supports Catppuccin officially, prefer the upstream Catppuccin port or the tool's native Catppuccin integration.

3. **Do not reintroduce machine-only theme writes as the primary mechanism**
   - The repo should stay the source of truth.
   - Avoid runtime theme generators unless there is a very strong reason.

4. **Install architecture is layered**
   - `install/bootstrap/` → minimal host bootstrap
   - `install/categories/` → category orchestration scripts
   - `install/lib/` → shared helpers
   - `install/profiles/` → platform entrypoints for full setup
   - `install/tools/` → per-tool/per-app installers
   - `install/agents/` → per-agent installers
   - `install/languages/` → per-language installers

## Directory map

```text
dotfiles/
├── install.sh                 # minimal bootstrap entrypoint
├── configs/                   # stow packages
├── install/
│   ├── bootstrap/
│   ├── categories/
│   ├── lib/
│   ├── profiles/
│   ├── tools/
│   ├── agents/
│   └── languages/
├── scripts/
│   ├── clean-backups.sh
│   └── update.sh
└── README.md / AGENTS.md
```

## What is generated vs hand-maintained

### Hand-maintained
- Most files under `configs/`
- Install scripts under `install/`
- Tool-specific Catppuccin config checked into `configs/`

### Generated / cached at runtime
- Tool plugin downloads under home-directory runtime paths (for example TPM plugins or Vim packages)
- Backup files created during Stow conflict handling (`*.backup`)

## Shell / script conventions

- Use `#!/usr/bin/env bash` for scripts unless there is a strong reason not to
- Prefer `set -euo pipefail`
- Keep scripts idempotent where possible
- Centralize shared helpers in `install/lib/`
- Prefer one responsibility per script
- Use clear section comments only when helpful; avoid noise

## Stow conventions

- `configs/.stowrc` sets target `~`
- Stow packages should map cleanly onto XDG locations whenever possible
- Do not create hidden one-off deployment paths outside `configs/`
- If a tool is part of the managed system, prefer a Stow package over ad hoc copying
- Unmanaged conflicts should be backed up next to the target as `*.backup`
- Backup cleanup should only delete backups for known managed targets

## Theme conventions

- Catppuccin Mocha is the only supported theme flavor in this repo
- Prefer official upstream Catppuccin theme files when available
- Keep theme naming explicit in config filenames when it improves clarity (for example `catppuccin-mocha.toml`)
- If a new themed tool is added, wire it directly into `configs/` and installer flows without adding a theme switcher

## Install flow conventions

- `install.sh` should stay minimal and two-phase
- The long-running setup flow belongs in `dotfiles install` / `install/categories/`
- The install menu should stay category-first even if the implementation is app-based underneath
- `Install Everything` should exclude languages
- Per-tool installers should live in `install/tools/app-*.sh`
- Per-agent installers should live in `install/agents/app-*.sh`
- Per-language installers should live in `install/languages/app-*.sh`
- Installer and maintenance flows should remain idempotent on an existing WSL machine

## Important constraints

- Never overwrite user-specific git identity without explicit instruction
- Keep future distro/OS support in mind when introducing assumptions
- Avoid broad `.gitignore` patterns that hide legitimate tracked files
- Prefer explicit paths and explicit ownership of generated files

## Testing expectations for agents

Before finishing a substantial change, try to validate with:
- `bash -n` on all changed shell scripts
- `zsh -n` on zsh config changes
- `stow -n -v <package>` where relevant
- non-interactive command checks for `dotfiles` and install/profile entrypoints

## Current architecture intent

This repo is moving toward:
- one user-facing command: `dotfiles`
- tracked Catppuccin Mocha config instead of theme-switching state
- category-first install UX backed by per-app installer scripts
- clean progress-oriented install feedback
- modular, extensible install logic
- clean future extension for Arch, Fedora, macOS, and desktop Linux variants
