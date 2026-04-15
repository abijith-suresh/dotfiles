# Dotfiles

Personal dotfiles for WSL Ubuntu and native Ubuntu/Debian Linux.
Managed with [GNU Stow](https://www.gnu.org/software/stow/) and organized around one primary command: `dotfiles`.

---

## Quick Start

```bash
git clone https://github.com/abijith-suresh/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

### Install flow on a fresh system

`install.sh` is intentionally small.

It does only enough to bootstrap the real workflow:
1. Detect platform (`wsl` or `linux`)
2. Install minimal prerequisites (`git`, `curl`, `wget`, `jq`, `stow`, `gum`)
3. Hand off to `dotfiles install --profile <platform>`

After that, the real setup is handled by the `dotfiles` CLI and the scripts under `install/`.

---

## The `dotfiles` command

Once installed, the main workflow is:

```bash
dotfiles              # Interactive menu
dotfiles install      # Full setup, languages, or coding agents
dotfiles theme        # Switch the active theme
dotfiles update       # Update system and managed tools
```

This is the preferred interface after the first bootstrap.

---

## Themes

Themes are **repo-backed**, not just machine-local.

When you run:

```bash
dotfiles theme tokyo-night
```

it updates:
- `themes/current-theme`
- tracked config outputs inside `configs/`
- then re-stows the affected packages

So the repo remains the source of truth for the active theme.

### Themed tools

Themes currently apply to:
- `starship`
- `neovim`
- `btop`
- `zellij`
- `alacritty`

### Available themes

- catppuccin
- tokyo-night
- nord
- gruvbox
- everforest
- kanagawa
- rose-pine
- matte-black
- osaka-jade
- ristretto

---

## Repository structure

```text
dotfiles/
├── install.sh                 # Minimal bootstrap entrypoint
├── configs/                   # GNU Stow packages (source of truth for deployed config)
│   ├── alacritty/
│   ├── bash/
│   ├── bat/
│   ├── bin/                   # ~/.local/bin/dotfiles
│   ├── btop/
│   ├── fastfetch/
│   ├── fzf/
│   ├── git/
│   ├── nvim/
│   ├── ripgrep/
│   ├── starship/
│   ├── tmux/
│   ├── vim/
│   ├── zellij/
│   └── zsh/
├── install/
│   ├── bootstrap/             # Minimal host bootstrapping
│   ├── lib/                   # Shared helpers
│   ├── profiles/              # Orchestrated install flows
│   ├── tools/                 # Per-tool installers
│   ├── agents/                # Per-agent installers
│   └── languages/             # Per-language installers + selector
├── scripts/
│   ├── theme.sh               # Repo-backed theme application
│   ├── update.sh              # Delegates to dotfiles update
│   └── generate-starship-themes.sh
├── themes/
│   ├── current-theme          # Active theme state
│   └── <theme>/               # Theme source assets
├── README.md
├── AGENTS.md
└── PLAN.md                    # Local planning reference (not required in commits)
```

---

## Tooling defaults

### Shell
- Primary shell: `zsh`
- Bash fallback config is also maintained
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

The interactive installer can also set these up for you via:

```bash
dotfiles install
```

---

## Coding agents

Coding agents are split into per-agent installers under `install/agents/`.

Available installers include:
- pi
- claude
- codex
- gemini
- copilot
- opencode

You can install all or selected ones through:

```bash
dotfiles install
```

---

## Extending to new distros / OSes

The repo is structured so future platform work is additive:

- `install/bootstrap/` for package-manager-level bootstrapping
- `install/profiles/` for platform orchestration
- `install/tools/`, `install/agents/`, `install/languages/` for reusable installers

Planned future targets:
- Arch Linux
- Fedora
- macOS

---

## Troubleshooting

### WSL Docker completion bug

Broken Docker completion symlinks under WSL can interfere with zsh startup.
The WSL install profile removes the common broken file and clears `.zcompdump*`.

### Stow conflicts

If you already have unmanaged config files, Stow may report conflicts.
Back them up, remove them, and restow the affected package.

Example:

```bash
mv ~/.config/btop/btop.conf ~/.config/btop/btop.conf.backup
cd ~/.dotfiles/configs
stow --restow btop
```

### Theme switching and backups

If `dotfiles theme` encounters unmanaged files for theme-managed targets,
it may back them up as `*.pre-dotfiles-backup` before re-stowing.

---

## Philosophy

- one primary workflow: `dotfiles`
- repo-backed state instead of hidden machine-only state
- GNU Stow as the deployment model
- modular install scripts
- easy future extension to other distros and operating systems
