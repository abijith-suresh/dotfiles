# Dotfiles

My terminal setup for WSL Ubuntu, Ubuntu, and Debian. `install.sh` installs tools
and deploys the configuration in `configs/` with GNU Stow. The theme is Catppuccin
Mocha.

Fedora and Arch support is experimental. macOS is untested.

## Install

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/abijith-suresh/dotfiles/main/boot.sh)"
```

To test an existing branch, replace `your-branch-name` below:

```bash
DOTFILES_REF=your-branch-name bash -c "$(curl -fsSL https://raw.githubusercontent.com/abijith-suresh/dotfiles/main/boot.sh)"
```

Or install from a local checkout:

```bash
git clone https://github.com/abijith-suresh/dotfiles.git ~/.dotfiles
~/.dotfiles/install.sh
```

Bootstrap pulls with `--ff-only` and disables autostash. If local changes conflict
with an update, resolve them and rerun bootstrap.

## Configuration and backups

The installer sets up terminal tools, coding agents, language runtimes, Vim,
Neovim, zsh plugins, Starship, and tmux plugins. It stows the packages in
`configs/` and backs up conflicting unmanaged files beside their original paths.

Zsh loads `~/.config/zsh/.zshenv` for shared environment definitions. History uses
`~/.local/state`; caches use `~/.cache`. The zsh rc also reads a regular
`~/.zshrc` for additions from third-party installers, with guards against symlinks,
same-file links, and recursive sourcing. Stow does not manage `~/.zshrc`.

Review install backups, then remove them with:

```bash
~/.dotfiles/scripts/clean-backups.sh --dry-run
~/.dotfiles/scripts/clean-backups.sh --yes
```

## Agent settings

Fresh installs stow Pi settings at `~/.pi/agent/settings.json` and Codex settings
at `~/.codex/config.toml`. Existing settings that do not resolve to this checkout
stay active, including files a CLI creates by replacing a symlink. The installer
reports them and deploys the other files in the package. It stops if a parent
symlink blocks deployment of preserved settings.

To replace an owned settings file with tracked settings, review and save it,
remove the live path, then rerun `install.sh`. Agent state stays in native
directories, so credentials do not need to move.

A CLI can write through a settings symlink and dirty the checkout. Review diffs
before committing. Keep credentials, project trust, runtime state, and model
defaults out of Git. Tracked agent configs do not select a default model or
reasoning settings. Fresh installs do not configure MCP servers; existing owned
Codex settings retain their local MCP blocks. Railway uses its
[official CLI](https://docs.railway.com/cli).

`install.sh` updates Pi to the latest stable npm release. Pi loads the local
TypeScript extensions directly through its SDK, without an extension dependency
install. The [Pi subagent guide](configs/pi/.pi/agent/skills/subagents/SKILL.md) covers
foreground and background tasks. `ask_user` accepts related questions together.
OpenCode installs from the official v2 channel, upgrades existing v1 installs,
and leaves v2 installs alone.

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for validation commands and the workflow,
[AGENTS.md](AGENTS.md) for repository rules, and
[docs/t3-code.md](docs/t3-code.md) for T3 Code setup.
