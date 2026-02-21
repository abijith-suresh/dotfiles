# Dotfiles

My personal dotfiles for WSL Ubuntu and native Ubuntu/Debian Linux.
Managed with [GNU Stow](https://www.gnu.org/software/stow/) for symlink management.

---

## Table of Contents

- [Structure](#structure)
- [Quick Start](#quick-start)
- [Supported Platforms](#supported-platforms)
- [Configs](#configs)
- [Scripts](#scripts)
- [Troubleshooting](#troubleshooting)

---

## Structure

```
dotfiles/
├── bootstrap.sh         # One-shot setup script (run this first)
├── configs/             # Config files organized by app (GNU Stow packages)
│   ├── bat/             # bat (cat replacement)
│   ├── bash/            # Bash shell
│   ├── fzf/             # fzf fuzzy finder
│   ├── git/             # Git (XDG: ~/.config/git/)
│   ├── nvim/            # Neovim
│   ├── ripgrep/         # ripgrep
│   ├── starship/        # Starship prompt
│   ├── tmux/            # tmux
│   └── zsh/             # Zsh (XDG: ~/.config/zsh/)
├── install/
│   └── linux.sh         # Ubuntu/Debian package installer
├── scripts/
│   └── update.sh        # Update plugins and tools
└── wallpapers/
```

---

## Quick Start

```bash
git clone https://github.com/abijith-suresh/dotfiles.git ~/Dotfiles
cd ~/Dotfiles
./bootstrap.sh
```

The bootstrap script will:
1. Install packages via `apt`
2. Install [Zinit](https://github.com/zdharma-continuum/zinit) plugin manager
3. Create XDG base directories
4. Stow all configs
5. Set zsh as your default shell (if not already)

**Flags:**
```bash
./bootstrap.sh --dry-run        # Preview steps without making changes
./bootstrap.sh --skip-packages  # Skip apt install, stow only
```

---

## Supported Platforms

| Platform | Status |
|---|---|
| Ubuntu (WSL) | Supported |
| Ubuntu / Debian (native) | Supported |
| macOS | Planned — [#11](https://github.com/abijith-suresh/dotfiles/issues/11) |
| Fedora | Planned — [#12](https://github.com/abijith-suresh/dotfiles/issues/12) |
| Arch Linux | Planned — [#13](https://github.com/abijith-suresh/dotfiles/issues/13) |

---

## Configs

All configs follow the [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html) standard.

### Stow commands

```bash
cd configs

# Individual packages
stow zsh
stow git
stow bat
stow starship
stow nvim
stow fzf
stow ripgrep
stow tmux

# All at once
stow zsh git bat starship nvim fzf ripgrep tmux
```

### zsh

- Entry point: `~/.zshenv` → sets `ZDOTDIR=$HOME/.config/zsh` and XDG vars
- Main config: `~/.config/zsh/.zshrc`
- Aliases: `~/.config/zsh/.zsh_aliases`
- Functions: `~/.config/zsh/.zsh_functions`
- Plugin manager: [Zinit](https://github.com/zdharma-continuum/zinit)
- Prompt: [Starship](https://starship.rs/)

### git

- Config: `~/.config/git/config`
- Global ignore: `~/.config/git/ignore`

### Neovim

Minimal setup — 7 plugins:

| Plugin | Purpose |
|---|---|
| catppuccin/nvim | Colorscheme (Mocha) |
| nvim-treesitter | Syntax highlighting |
| telescope.nvim | Fuzzy finder |
| nvim-lspconfig | LSP client |
| mason.nvim | LSP server installer |
| mason-lspconfig | LSP bridge |
| nvim-cmp | Completion |

Auto-installed LSP servers: `lua_ls`, `pyright`, `ts_ls`, `html`, `cssls`

---

## Scripts

- `scripts/update.sh` — Update Zinit plugins, Starship, and system packages

---

## Troubleshooting

### WSL: `compinit: no such file or directory: /usr/share/zsh/vendor-completions/_docker`

**Cause:** Docker Desktop's WSL integration writes a completion file into WSL. When Docker
Desktop updates or its WSL integration changes state, the file becomes a broken symlink.
`compinit` reads the stale cache and fails to find the file on disk.

**Fix:** `bootstrap.sh` (and `install/linux.sh`) automatically remove the broken file and
clear the completion cache:

```bash
sudo rm -f /usr/share/zsh/vendor-completions/_docker
rm -f ~/.zcompdump*
```

Docker tab-completion continues to work because `.zshrc` loads it via Zinit from Docker's
official GitHub repo — no dependency on Docker Desktop's WSL integration.
