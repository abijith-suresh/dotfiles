# Architecture

## Entrypoints

- `boot.sh` is the remote bootstrap entrypoint. It installs minimal clone prerequisites, clones or updates `~/.dotfiles`, checks out `DOTFILES_REF` or `main`, and runs `install.sh`.
- `install.sh` is the local setup entrypoint. It does not update the repo and has no flags.

## Install Phases

`install.sh` runs explicit ordered lists:

1. Detect platform and package manager.
2. Bootstrap base packages.
3. Create XDG directories.
4. Install foundation apps: `mise`, `zsh`, `git`.
5. Install CLI/TUI apps.
6. Install coding agent CLIs.
7. Install language runtimes and editor tooling.
8. Stow config packages.
9. Print a final summary.

Script order is controlled in `install.sh`, not by filename sorting.

## Directory Layout

```text
install/
├── lib.sh
├── bootstrap/
├── apps/
│   ├── cli/
│   └── agents/
├── languages/
└── stow.sh
```

`install/lib.sh` contains shared primitives only: platform detection, package installation, output helpers, failure summaries, download helpers, and common path setup.

## Config Deployment

`configs/` is the source of truth for deployed configuration.

`install/stow.sh` owns config deployment. It uses an explicit `STOW_PACKAGES` list, backs up unmanaged conflicts, and runs GNU Stow with `--no-folding` so shared directories like `~/.config` remain real directories.

Backup naming:

- first backup: `target.backup`
- if taken: `target.backup.YYYYMMDD-HHMMSS`
- if still taken: `target.backup.YYYYMMDD-HHMMSS.N`

`scripts/clean-backups.sh` is a manual helper. It only removes backups corresponding to known managed Stow targets.

## Install Source Policy

Each app script documents its source policy in a short comment. Source policies must be based on official or canonical install docs at the time of editing.

General defaults:

- Use package managers for stable packages where the package is current enough.
- Use official upstream installers or releases when distro packages are stale, missing, renamed awkwardly, or upstream recommends another path.
- Use Homebrew for macOS CLI tools and future casks.
- Use Flatpak for future Linux GUI apps.
- Use `mise` for language runtimes.

## Managed Tools

Foundation:

- `mise`
- `zsh`
- `git`

CLI/TUI:

- `bat`
- `btop`
- `eza`
- `fastfetch`
- `fd`
- `fzf`
- `gh`
- `lazydocker`
- `lazygit`
- `neovim`
- `ripgrep`
- `shellcheck`
- `shfmt`
- `starship`
- `tmux`
- `vim`
- `zellij`
- `zoxide`

Agents:

- `claude`
- `codex`
- `copilot`
- `opencode`
- `pi`

Languages:

- `node`
- `bun`
- `java`
- `python`
- `go`
