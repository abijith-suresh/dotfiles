# Dotfiles

Personal dotfiles for WSL Ubuntu and native Ubuntu/Debian Linux.
Managed with [GNU Stow](https://www.gnu.org/software/stow/) for symlink management.

---

## Table of Contents

- [Quick Start](#quick-start)
- [The `dotfiles` Command](#the-dotfiles-command)
- [Themes](#themes)
- [Structure](#structure)
- [Config Details](#config-details)
- [Supported Platforms](#supported-platforms)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

```bash
git clone https://github.com/abijith-suresh/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

The installer will:
1. Update system packages via apt
2. Install core CLI tools (bat, eza, fzf, ripgrep, zoxide, etc.)
3. Install terminal tools (zsh + zinit, tmux, zellij, nvim, mise, etc.)
4. Optionally install coding agents (pi, claude, codex, gemini, opencode)
5. Optionally set up programming languages via mise
6. Stow all config files
7. Apply the default theme (catppuccin)

**Flags:**
```bash
./install.sh --dry-run        # Preview steps without making changes
./install.sh --skip-packages  # Skip apt install, stow only
```

---

## The `dotfiles` Command

After installation, the `dotfiles` CLI is available in your PATH:

```bash
dotfiles              # Interactive menu
dotfiles theme        # Switch themes (gum-powered)
dotfiles update       # Update system, plugins, tools
dotfiles install      # Install additional tools/languages
```

---

## Themes

10 curated themes with consistent colors across all tools:

| Theme | Description |
|---|---|
| Catppuccin | Warm pastel palette (default) |
| Tokyo Night | Dark blue-tinted |
| Nord | Arctic blue palette |
| Gruvbox | Warm retro colors |
| Everforest | Soft green nature tones |
| Kanagawa | Japanese-inspired indigo |
| Rose Pine | Soft pink/purple |
| Matte Black | Neutral dark |
| Osaka Jade | Teal-green tones |
| Ristretto | Warm espresso browns |

Each theme applies to: zellij, btop, neovim, starship, and alacritty.

```bash
dotfiles theme            # Interactive selection
dotfiles theme catppuccin # Direct switch
```

---

## Structure

```
dotfiles/
├── install.sh            # Entry point — run this first
├── configs/              # Config files organized by app (GNU Stow packages)
│   ├── bash/             # Bash shell
│   ├── bat/              # bat (cat replacement)
│   ├── bin/              # dotfiles CLI
│   ├── btop/             # System monitor
│   ├── fastfetch/        # System info display
│   ├── fzf/              # fzf fuzzy finder
│   ├── git/              # Git (XDG: ~/.config/git/)
│   ├── nvim/             # Neovim
│   ├── ripgrep/          # ripgrep
│   ├── starship/         # Starship prompt
│   ├── tmux/             # tmux multiplexer
│   ├── vim/              # Vim fallback
│   ├── zellij/           # Zellij multiplexer
│   └── zsh/              # Zsh (XDG: ~/.config/zsh/)
├── install/
│   ├── linux.sh          # System package update
│   └── terminal/         # Per-tool install scripts
│       ├── required/     # gum (needed for UI)
│       ├── app-*.sh      # Individual tool installers
│       ├── agents.sh     # Coding agent installer
│       └── select-language.sh
├── scripts/
│   ├── theme.sh          # Theme switcher
│   ├── update.sh         # Update delegation
│   └── generate-starship-themes.sh
├── themes/               # 10 color themes
│   └── <theme>/
│       ├── zellij.kdl
│       ├── btop.theme
│       ├── neovim.lua
│       ├── starship.toml
│       └── alacritty.toml
└── wallpapers/
```

---

## Config Details

All configs follow the [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html) standard.

### Shell (zsh)

- Entry point: `~/.zshenv` → sets `ZDOTDIR=$HOME/.config/zsh` and XDG vars
- Main config: `~/.config/zsh/.zshrc`
- Aliases: `~/.config/zsh/.zsh_aliases` (minimal set — use lazygit for complex git)
- Functions: `~/.config/zsh/.zsh_functions`
- Plugin manager: [Zinit](https://github.com/zdharma-continuum/zinit)
- Prompt: [Starship](https://starship.rs/)

### Language Management (mise)

[mise](https://mise.jdx.dev/) replaces NVM, SDKMAN, and other version managers:
```bash
mise use --global node@lts    # Install Node.js LTS
mise use --global java@latest # Install Java
mise use --global python@latest
mise ls                       # List installed tools
```

### Multiplexers

- **tmux** — configured with TPM, Catppuccin theme, vim-style keybindings
- **Zellij** — modern alternative, locked-mode vim-style keybindings

### Git

- Config: `~/.config/git/config`
- Global ignore: `~/.config/git/ignore`

---

## Supported Platforms

| Platform | Status |
|---|---|
| Ubuntu (WSL) | ✅ Supported |
| Ubuntu / Debian (native) | ✅ Supported |
| macOS | 🔜 Planned |
| Fedora | 🔜 Planned |
| Arch Linux | 🔜 Planned |

---

## Troubleshooting

### WSL: `compinit: no such file or directory: /usr/share/zsh/vendor-completions/_docker`

Docker Desktop's WSL integration can leave broken symlinks. Fixed automatically by `install.sh`.

```bash
sudo rm -f /usr/share/zsh/vendor-completions/_docker
rm -f ~/.zcompdump*
```

### Stow conflicts

If stow reports conflicts with existing config files:

```bash
# Back up existing file, then stow
mv ~/.config/btop/btop.conf ~/.config/btop/btop.conf.bak
cd ~/.dotfiles/configs && stow btop
```
