# Dotfiles

Personal dotfiles for WSL Ubuntu and native Ubuntu/Debian Linux.
Managed with [GNU Stow](https://www.gnu.org/software/stow/).

---

## Quick Start

```bash
git clone https://github.com/abijith-suresh/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

### Install flow on a fresh system

`install.sh` is the single entrypoint.

1. Bootstraps system dependencies (via `install/bootstrap/packages.sh`)
2. Installs all CLI tools (via `install/cli/`)
3. Installs languages (via `install/languages/`)
4. Stows all configuration packages (from `configs/`)

---

## Theme

This repo is now intentionally **single-theme**: Catppuccin Mocha.

There is no theme switcher anymore. The source of truth lives directly in the tracked files under `configs/`, which keeps the setup simpler and easier to maintain.

### Themed tools

Catppuccin is applied directly to:
- `bat`
- `btop`
- `fzf`
- `lazydocker`
- `lazygit`
- `neovim`
- `starship`
- `tmux`
- `vim`
- `zellij`

---

## Repository structure

```text
dotfiles/
├── install.sh                 # Single entrypoint
├── configs/                   # GNU Stow packages (source of truth for deployed config)
│   ├── bat/
│   ├── bin/                   # ~/.local/bin/dotfiles
│   ├── btop/
│   ├── claude/                # Claude Code config
│   ├── codex/                 # Codex CLI config
│   ├── fastfetch/
│   ├── fzf/
│   ├── git/
│   ├── lazydocker/
│   ├── lazygit/
│   ├── nvim/
│   ├── opencode/              # opencode config
│   ├── pi/                    # PI coding agent config
│   ├── ripgrep/
│   ├── starship/
│   ├── tmux/
│   ├── vim/
│   ├── zellij/
│   └── zsh/
├── install/
│   ├── bootstrap/             # System package bootstrapping
│   │   └── packages.sh        # OS-detecting package installer
│   │   └── packages/          # Per-package-manager scripts
│   ├── cli/                   # Per-tool/per-agent installers
│   └── languages/             # Per-language installers
├── scripts/
│   └── clean-backups.sh       # Removes managed .backup files
├── README.md
└── AGENTS.md
```

---

## Tooling defaults

### Shell
- Primary shell: `zsh`
- Prompt: `starship`
- Plugin manager: `zinit`
- Runtime/version manager: `mise`

### Terminal tools
- Search: `ripgrep`
- Fuzzy finder: `fzf`
- File finder: `fd`
- File listing: `eza`
- System info: `fastfetch`
- System monitor: `btop`
- Git TUI: `lazygit`
- Docker TUI: `lazydocker`
- GitHub CLI: `gh`

### Multiplexers
- `tmux` (kept)
- `zellij` (added from omakub-inspired direction)

---

## Language management

`mise` is the single version manager.

Examples:

```bash
mise use --global node@lts
mise use --global java@latest
mise use --global python@latest
mise use --global go@latest
```

The installer runs all language installers under `install/languages/`.

---

## Coding agents

Coding agents are installed via scripts under `install/cli/`.

Available installers include:
- pi
- claude
- codex
- gemini
- copilot
- opencode

---

## Extending to new distros / OSes

The repo is structured so future platform work is additive:

- `install/bootstrap/` for package-manager-level bootstrapping
- `install/cli/` for reusable tool/agent installers
- `install/languages/` for language installers

Planned future targets:
- Arch Linux
- Fedora
- macOS

---

## Troubleshooting

### WSL Docker completion bug

Broken Docker completion symlinks under WSL can interfere with zsh startup.
The install now removes the common broken file and clears `.zcompdump*`.

### Stow conflicts

If a conflict involves a directory shape mismatch, you may need to resolve it manually.
Example:

```bash
mv ~/.config/btop/btop.conf ~/.config/btop/btop.conf.backup
cd ~/.dotfiles/configs
stow --restow btop
```

---

## Philosophy

- tracked config as the source of truth
- Catppuccin Mocha everywhere instead of a theme-switching layer
- GNU Stow as the deployment model
- modular install scripts
- easy future extension to other distros and operating systems
