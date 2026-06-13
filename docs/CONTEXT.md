# Context

## Product Truth

This is a personal dotfiles repo. It is not a dotfiles framework, a public distribution, or a customizable installer.

## Goals

- Make a fresh machine match my preferred terminal setup quickly.
- Keep tracked config in `configs/` as the source of truth.
- Keep install behavior direct, non-interactive, idempotent, and understandable.
- Support current WSL Ubuntu / Ubuntu / Debian use, while keeping Fedora, Arch, and macOS paths straightforward to test later.

## Non-Goals

- No install menus.
- No optional selectors.
- No theme switcher.
- No profiles.
- No uninstall framework.
- No migration framework.
- No local override UX.
- No Docker or Podman setup.
- No GUI app or desktop environment setup yet.

## Supported Platforms

- Supported: WSL Ubuntu, Ubuntu, Debian
- Experimental: Fedora, Arch
- Untested: macOS

## Success Criteria

- `boot.sh` can bootstrap a machine from a curl command.
- `install.sh` can be rerun safely.
- Tool install failures for non-critical leaf apps are visible in the final summary.
- Critical setup failures stop immediately.
- Config conflicts are backed up, repo configs are stowed, and the summary reports what changed.
- `scripts/validate.sh` catches broken shell syntax, Stow package drift, formatting drift, and common shell issues.
