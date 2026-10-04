# Contributing

## Validation

Run validation before submitting changes:

```bash
scripts/validate.sh
```

`scripts/validate.sh` runs:

- `git diff --check`
- `bash -n`
- `zsh -n`
- `shfmt -i 2 -ci -d` when `shfmt` is installed
- `shellcheck` when installed
- Stow package list consistency
- Stow dry-run against a temporary home

Validation does not change files. Run the Stow tests after deployment changes:

```bash
scripts/test-stow.sh
```

They use temporary homes to check clean and repeated deployment, conflict
backups, and preservation of existing Pi and Codex settings and auth files.
Run `scripts/test-pi-installer.sh` after Pi installer changes. There is no GitHub
Actions workflow, so these checks run locally.

Pi extension development uses Node 24 or newer. Install the development tools
in the checkout, then typecheck and run the offline behavior tests:

```bash
npm ci --ignore-scripts
npm run check:pi
npm run test:pi
npm run format:check
PI_TEST_RUNTIME="$PWD/node_modules/@earendil-works/pi-coding-agent" scripts/test-pi-installer.sh
```

Tests and development dependencies stay outside `configs/`. The SDK in the
lockfile is used for development only; installation still uses Pi's latest
stable CLI. The last command checks discovery through that SDK in a fresh
Stow home with no extension dependency install.

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
5. Link the official installation docs in a script comment.
6. Update `AGENTS.md` if repository constraints or managed-tool behavior changes.

## Removing a tool

1. Remove its installer script.
2. Remove it from `install.sh`.
3. Remove its config package if it has one.
4. Remove it from `install/stow.sh`.
5. Update `README.md`, `AGENTS.md`, or this file when the change affects them.
