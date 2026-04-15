# AGENTS.md - Dotfiles Repository Guide

This guide is for agentic coding assistants working in this personal dotfiles repository. It covers installation scripts, code style conventions, and repository structure.

## Repository Overview

Personal dotfiles repository managed with GNU Stow. Contains configuration files for shell environments, editors, terminal tools, and development utilities.

**Primary Purpose**: Manage and version control personal configuration files across multiple machines and operating systems.

## Directory Structure

```
dotfiles/
├── install.sh          # Entry point — minimal bootstrap
├── configs/            # All configuration files (GNU Stow packages)
│   ├── bin/            # dotfiles CLI → ~/.local/bin/dotfiles
│   ├── zsh/            # Zsh shell (primary)
│   ├── bash/           # Bash shell (fallback)
│   ├── nvim/           # Neovim (LazyVim)
│   ├── vim/            # Vim (fallback)
│   ├── tmux/           # tmux
│   ├── zellij/         # Zellij
│   ├── git/            # Git config
│   ├── starship/       # Prompt
│   ├── bat/            # bat
│   ├── btop/           # System monitor
│   ├── fastfetch/      # System info
│   ├── fzf/            # Fuzzy finder
│   └── ripgrep/        # Search
├── install/
│   ├── linux.sh        # System package update
│   └── terminal/       # Per-tool install scripts
│       ├── required/   # gum (UI dependency)
│       └── app-*.sh    # Idempotent per-tool installers
├── scripts/
│   ├── theme.sh        # Theme switcher
│   └── update.sh       # Update delegation
└── themes/             # 10 color themes
    └── <theme>/
        ├── zellij.kdl, btop.theme, neovim.lua
        ├── starship.toml, alacritty.toml
```

## Installation & Setup

### First-time setup
```bash
./install.sh                    # Full interactive setup
./install.sh --dry-run          # Preview without changes
./install.sh --skip-packages    # Stow only, no apt
```

### Per-tool scripts
Each `install/terminal/app-*.sh` is:
- Self-contained and idempotent
- Can be run independently: `bash install/terminal/app-zellij.sh`
- Sourced in a loop by `install.sh`

### Stow commands
```bash
cd configs
stow <package_name>      # Deploy
stow -D <package_name>   # Remove
stow -n -v <package>     # Dry-run preview
stow --restow <package>  # Re-link
```

### The dotfiles CLI
```bash
dotfiles              # Interactive menu (requires gum)
dotfiles theme        # Switch themes
dotfiles update       # Update everything
dotfiles install      # Install additional tools
```

## Code Style Guidelines

### Shell Scripts (Bash/Zsh)

- **Shebang**: `#!/bin/bash` or `#!/usr/bin/env bash`
- **Error handling**: `set -e` at start for critical scripts
- **Indentation**: 2 spaces
- **Variables**: lowercase, quoted: `"$variable"`
- **Lists**: arrays: `packages=(bat btop eza)`
- **Comments**: `# ---` for section headers
- **Idempotent**: install scripts should be safe to re-run

### Lua (Neovim Config)

- 2 spaces indentation
- One plugin per file in `lua/plugins/`
- Use `vim.opt` for options, `vim.keymap` for keymaps

## Key Tools

- **Shell**: zsh (Zinit) + bash fallback
- **Prompt**: Starship
- **Version manager**: mise (replaces NVM, SDKMAN)
- **Multiplexer**: tmux + zellij
- **Editor**: Neovim (LazyVim) + vim fallback
- **Theme system**: 10 themes, switched via `dotfiles theme`

## Important Notes for Agents

1. **Never modify user-specific data** in .gitconfig (name, email)
2. **Preserve exact indentation** when editing config files
3. **Keep shell startup fast** — avoid expensive operations in .bashrc/.zshrc
4. **Maintain GNU Stow compatibility** — proper directory structure in configs/
5. **Theme files are in themes/** — don't hardcode colors in stowed configs
6. **Install scripts must be idempotent** — safe to run multiple times
7. **The dotfiles CLI depends on gum** — don't require gum in configs themselves

---

**Last Updated**: 2026-04-15
**Maintained by**: Abijith Suresh
