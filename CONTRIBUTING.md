# Contributing

## Workflow

1. Make scoped changes.
2. Keep docs in sync with behavior.
3. Run validation.
4. Commit by intent.

```bash
scripts/validate.sh
scripts/test-stow.sh
```

## Validation

Run checks locally. There is no GitHub Actions workflow. `scripts/test-stow.sh`
uses temporary homes to check clean and repeated deployment, conflict backups,
and preservation of existing Pi and Codex settings and auth files.

`scripts/validate.sh` runs:

- `git diff --check`
- `bash -n`
- `zsh -n`
- `shfmt -i 2 -ci -d` when `shfmt` is installed
- `shellcheck` when installed
- Stow package list consistency
- Stow dry-run against a temporary home

Validation is non-mutating.

## Formatting

Shell scripts use:

```bash
shfmt -i 2 -ci -w boot.sh install.sh install scripts
```

## Adding a tool

1. Add one script under `install/apps/cli/`, `install/apps/agents/`, or `install/languages/`.
2. Add it to the explicit list in `install.sh`.
3. If it has managed config, add a Stow package under `configs/`.
4. Add that package to `STOW_PACKAGES` in `install/stow.sh`.
5. Document the install source policy in the script using official/canonical docs.
6. Update `AGENTS.md` if repository constraints or managed-tool behavior changes.

## Removing a tool

1. Remove its installer script.
2. Remove it from `install.sh`.
3. Remove its config package if it has one.
4. Remove it from `install/stow.sh`.
5. Update `README.md`, `AGENTS.md`, or this file when the change affects them.
