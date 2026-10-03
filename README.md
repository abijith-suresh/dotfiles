# Dotfiles

Personal, opinionated terminal setup for my machines.

This repo exists to make a fresh machine feel like mine quickly. It installs the tools I use, then deploys the tracked config under `configs/` with GNU Stow.

Running `install.sh` also updates the Pi CLI to the latest npm release when it is already installed.

OpenCode installs from the official v2 release channel. An existing v1 install is migrated in place; a v2 install is left alone.

Pi and Codex settings are stowed at `~/.pi/agent/settings.json` and `~/.codex/config.toml` on fresh installs. Their native state directories stay in place, so no credentials need to move. Existing settings that are not linked to this checkout stay active, including files a CLI creates by replacing its symlink. The installer reports these files and deploys the rest of their package.

Changes through a settings symlink can dirty the checkout. Review the diff before committing and keep auth, project trust, runtime state, and model defaults out of Git. There is no runtime refresh command. To use tracked settings in place of an owned file, first review and save that file yourself, then remove the live path and rerun `install.sh`. The installer stops if a parent symlink blocks deployment of preserved settings.

Agent configs contain no default model or reasoning settings. Railway installs only its [official CLI](https://docs.railway.com/cli); fresh installs do not configure MCP servers. Existing owned Codex settings, including local MCP blocks, stay untouched.

## Install

On Linux, WSL Ubuntu, Ubuntu, or Debian:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/abijith-suresh/dotfiles/main/boot.sh)"
```

Test a branch:

```bash
DOTFILES_REF=your-branch-name bash -c "$(curl -fsSL https://raw.githubusercontent.com/abijith-suresh/dotfiles/main/boot.sh)"
```

Replace `your-branch-name` with a branch that exists in this repository.

Bootstrap updates with a fast-forward pull and disables autostash. If local config changes conflict with an update, it stops before installation. Review and resolve those changes yourself, then rerun bootstrap.

Local checkout:

```bash
git clone https://github.com/abijith-suresh/dotfiles.git ~/.dotfiles
~/.dotfiles/install.sh
```

## Platform status

- Supported: WSL Ubuntu, Ubuntu, Debian
- Experimental: Fedora, Arch
- Untested: macOS

## What it does

- Installs terminal tools, TUIs, coding agents, language runtimes, and editor tooling I use.
- Installs `zsh`, explicit zsh plugins, Starship, tmux plugins, Vim Catppuccin, and Neovim config.
- Stows tracked config packages from `configs/`.
- Backs up unmanaged config conflicts next to the original file before stowing repo config.

Zsh keeps shared environment definitions in `~/.config/zsh/.zshenv`. Shell history and caches use `~/.local/state` and `~/.cache`; configs for tools with XDG support use `~/.config`. The XDG rc also sources an existing regular `~/.zshrc`, so additions from third-party installers still load. It skips symlinks and same-file links and guards recursive sourcing. Stow does not manage `~/.zshrc`.

If backups are created during install, clean them later with:

```bash
~/.dotfiles/scripts/clean-backups.sh --dry-run
~/.dotfiles/scripts/clean-backups.sh --yes
```

## Development

Repo validation:

```bash
~/.dotfiles/scripts/validate.sh
~/.dotfiles/scripts/test-stow.sh
```

Repository guidance:

- [AGENTS.md](AGENTS.md) has agent rules and repository invariants.
- [CONTRIBUTING.md](CONTRIBUTING.md) describes the development workflow.
- [docs/t3-code.md](docs/t3-code.md) describes the T3 Code setup.
