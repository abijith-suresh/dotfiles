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
   - `install/bootstrap/` → system package bootstrapping
   - `install/cli/` → per-tool/per-agent installers
   - `install/languages/` → per-language installers

## Directory map

```text
dotfiles/
├── install.sh                 # Single entrypoint
├── configs/                   # stow packages
├── install/
│   ├── bootstrap/
│   │   └── packages.sh        # OS-detecting package installer
│   │   └── packages/          # Per-package-manager scripts
│   ├── cli/                   # Per-tool/per-agent installers
│   └── languages/             # Per-language installers
├── scripts/
│   └── clean-backups.sh
└── README.md / AGENTS.md
```

## What is generated vs hand-maintained

### Hand-maintained
- Most files under `configs/`
- Install scripts under `install/`

### Generated / cached at runtime
- Tool plugin downloads under home-directory runtime paths (for example TPM plugins or Vim packages)
- Backup files created during Stow conflict handling (`*.backup`)

## Shell / script conventions

- Use `#!/usr/bin/env bash` for scripts unless there is a strong reason not to
- Prefer `set -euo pipefail`
- Keep scripts idempotent where possible
- Each script under `install/cli/` is self-contained — no shared lib dependencies
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

- `install.sh` is the single entrypoint
- `install.sh` runs bootstrap, then CLI installers, then language installers, then stows all packages
- Per-tool installers live in `install/cli/app-*.sh`
- Per-agent installers live in `install/cli/app-*.sh`
- Per-language installers live in `install/languages/app-*.sh`
- Install scripts should remain idempotent on an existing WSL machine

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

## Current architecture intent

This repo is moving toward:
- a single `./install.sh` entrypoint
- tracked Catppuccin Mocha config instead of theme-switching state
- self-contained per-app installer scripts (no lib/ dependencies)
- clean future extension for Arch, Fedora, macOS, and desktop Linux variants
- configuration stow packages for coding agents (opencode, pi, claude, codex)
