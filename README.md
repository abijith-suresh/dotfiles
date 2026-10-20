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

The installer sets up terminal tools, language runtimes, Vim, Neovim, zsh
plugins, Starship, and tmux plugins, and installs coding agents without managing
their configuration. It stows the packages in `configs/` and backs up conflicting
unmanaged files beside their original paths.

Zsh loads `~/.config/zsh/.zshenv` for shared environment definitions. History uses
`~/.local/state`; caches use `~/.cache`. The zsh rc also reads a regular
`~/.zshrc` for additions from third-party installers, with guards against symlinks,
same-file links, and recursive sourcing. Stow does not manage `~/.zshrc`.

Review install backups, then remove them with:

```bash
~/.dotfiles/scripts/clean-backups.sh --dry-run
~/.dotfiles/scripts/clean-backups.sh --yes
```

## Coding agents

`install.sh` installs the agent CLIs and leaves their configuration alone. Each
CLI keeps its own native state directory; this repository does not stow agent
settings. Fresh installs do not configure MCP servers. Railway uses its
[official CLI](https://docs.railway.com/cli).

After installing Pi, `install.sh` installs
[Tangent](https://github.com/abijith-suresh/tangent) through Pi's native package
manager. The tagged source in `install/apps/agents/tangent.sh` is the version to
install, currently `0.0.1`. Tangent contains only the Catppuccin Mocha theme;
fresh Pi installs start on Pi's default theme. Pi's package checkout stays in its
native directory. Future Tangent updates require changing the tag in the
installer.

OpenCode installs from the official v2 channel, upgrades existing v1 installs,
and leaves v2 installs alone.

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for validation commands and the workflow,
and [AGENTS.md](AGENTS.md) for repository rules.
