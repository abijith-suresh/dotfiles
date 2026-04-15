# AGENTS.md - Dotfiles Repository Guide

This repository is a GNU Stow-based dotfiles system with repo-backed theme state and a modular install architecture.

## Core rules

1. **`configs/` is the source of truth for deployed configuration**
   - If a file should exist on the machine via Stow, its authoritative source lives in `configs/`.

2. **`themes/` contains theme source assets, not deployed config**
   - `themes/<theme>/...` are inputs
   - `scripts/theme.sh` writes the active outputs into `configs/`
   - `themes/current-theme` stores the selected theme name

3. **Do not reintroduce machine-only theme writes as the primary mechanism**
   - Theme switching should update repo-backed config first, then re-stow.

4. **Install architecture is layered**
   - `install/bootstrap/` → minimal host bootstrap
   - `install/lib/` → shared helpers
   - `install/profiles/` → orchestrated setup flows
   - `install/tools/` → per-tool installers
   - `install/agents/` → per-agent installers
   - `install/languages/` → per-language installers

## Directory map

```text
dotfiles/
├── install.sh                 # minimal bootstrap entrypoint
├── configs/                   # stow packages
├── install/
│   ├── bootstrap/
│   ├── lib/
│   ├── profiles/
│   ├── tools/
│   ├── agents/
│   └── languages/
├── scripts/
│   ├── theme.sh
│   ├── update.sh
│   └── generate-starship-themes.sh
├── themes/
│   ├── current-theme
│   └── <theme>/
└── README.md / AGENTS.md / PLAN.md
```

## What is generated vs hand-maintained

### Hand-maintained
- Most files under `configs/`
- Install scripts under `install/`
- Theme source assets under `themes/<theme>/`

### Generated / rewritten by theme switching
These are still repo-backed and tracked, but are updated by `scripts/theme.sh`:
- `configs/starship/.config/starship.toml`
- `configs/nvim/.config/nvim/lua/plugins/theme.lua`
- `configs/btop/.config/btop/themes/current.theme`
- `configs/zellij/.config/zellij/themes/current.kdl`
- `configs/alacritty/.config/alacritty/theme.toml`
- `themes/current-theme`

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

## Theme system conventions

- Adding a new theme means adding a complete directory under `themes/<name>/`
- Keep theme directory contents consistent across themes
- If a new themed tool is added, theme switching must remain repo-backed
- Do not hardcode a theme in configs when it should be generated from the active theme

## Install flow conventions

- `install.sh` should stay minimal
- The long-running setup flow belongs in `dotfiles install` / `install/profiles/`
- Per-tool installers should live in `install/tools/app-*.sh`
- Per-agent installers should live in `install/agents/app-*.sh`
- Per-language installers should live in `install/languages/app-*.sh`

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
- non-interactive command checks for `dotfiles`, `theme.sh`, and install/profile entrypoints

## Current architecture intent

This repo is moving toward:
- one user-facing command: `dotfiles`
- repo-backed active theme state
- modular, extensible install logic
- clean future extension for Arch, Fedora, macOS, and desktop Linux variants
