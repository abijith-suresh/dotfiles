# Dotfiles

Personal, opinionated terminal setup for my machines.

This repo exists to make a fresh machine feel like mine quickly. It installs the tools I use, then deploys the tracked config under `configs/` with GNU Stow.

## Install

Remote bootstrap:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/abijith-suresh/dotfiles/main/boot.sh)"
```

Test a branch:

```bash
DOTFILES_REF=refactor/dotfiles-restructure bash -c "$(curl -fsSL https://raw.githubusercontent.com/abijith-suresh/dotfiles/main/boot.sh)"
```

Local checkout:

```bash
git clone https://github.com/abijith-suresh/dotfiles.git ~/.dotfiles
~/.dotfiles/install.sh
```

## Platform Status

- Supported: WSL Ubuntu, Ubuntu, Debian
- Experimental: Fedora, Arch
- Untested: macOS

## What It Does

- Installs terminal tools, TUIs, coding agents, language runtimes, and editor tooling I use.
- Installs `zsh`, explicit zsh plugins, Starship, tmux plugins, Vim Catppuccin, and Neovim config.
- Stows tracked config packages from `configs/`.
- Backs up unmanaged config conflicts next to the original file before stowing repo config.

If backups are created during install, clean them later with:

```bash
~/.dotfiles/scripts/clean-backups.sh --dry-run
~/.dotfiles/scripts/clean-backups.sh --yes
```

## Development

Repo validation:

```bash
~/.dotfiles/scripts/validate.sh
```

See `docs/` for context, architecture, and contribution workflow.
