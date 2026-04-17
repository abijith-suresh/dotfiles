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
3. Stow the `bin` package so the `dotfiles` CLI is available
4. Optionally launch the interactive `dotfiles install` flow

`install.sh` does **not** force the full profile anymore.
It bootstraps the machine, exposes the CLI, and leaves the real setup to `dotfiles install`.

---

## The `dotfiles` command

Once installed, the main workflow is:

```bash
dotfiles                    # Interactive menu
dotfiles install            # Category-based installer
dotfiles install everything # Base + terminal tools + agents + default theme
dotfiles theme              # Switch the active theme
dotfiles update             # Update system and managed tools
dotfiles clean-backups      # Delete dotfiles-created .backup files
```

This is the preferred interface after the first bootstrap.

### Install categories

`dotfiles install` is category-first:
- Base Setup
- Terminal Tools
- Languages
- Coding Agents
- Theme
- Clean Backups
- Install Everything

`Install Everything` intentionally excludes languages.

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
│   ├── categories/            # Category orchestration scripts
│   ├── lib/                   # Shared helpers
│   ├── profiles/              # Platform entrypoints for full install
│   ├── tools/                 # Per-app/per-tool installers
│   ├── agents/                # Per-agent installers
│   └── languages/             # Per-language installers + selector
├── scripts/
│   ├── clean-backups.sh       # Removes managed .backup files
│   ├── theme.sh               # Repo-backed theme application
│   ├── update.sh              # Delegates to dotfiles update
│   └── generate-starship-themes.sh
├── themes/
│   ├── current-theme          # Active theme state
│   └── <theme>/               # Theme source assets
├── README.md
└── AGENTS.md
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

The category installer will install them as a group through:

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

The install flow now auto-backs up many unmanaged file conflicts as `*.backup`
before re-stowing packages.

If a conflict involves a directory shape mismatch, you may still need to resolve it manually.
Example:

```bash
mv ~/.config/btop/btop.conf ~/.config/btop/btop.conf.backup
cd ~/.dotfiles/configs
stow --restow btop
```

### Theme switching and backups

If `dotfiles theme` or `dotfiles install` encounters unmanaged files for managed targets,
it may back them up as `*.backup` before re-stowing.

After testing, you can remove those backups with:

```bash
dotfiles clean-backups
```

---

## Philosophy

- one primary workflow: `dotfiles`
- repo-backed state instead of hidden machine-only state
- GNU Stow as the deployment model
- modular install scripts
- easy future extension to other distros and operating systems
