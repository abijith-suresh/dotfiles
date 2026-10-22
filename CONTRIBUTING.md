# Contributing

## Formatting

Shell scripts use:

```bash
shfmt -i 2 -ci -w boot.sh install.sh install scripts
```

## Adding a tool

1. Register it in `install/manifest.bash` with one `register` record. Plain
   package installs are records only (`source=pkg`); record the official
   documentation URL with `docs=` whenever the tool has one.
2. Only when the install needs real logic, add one script under
   `install/apps/cli/`, `install/apps/agents/`, or `install/languages/` and
   point the record at it with `script=`.
3. If it has managed config, add a Stow package under `configs/`. Agent CLIs are installed only, so they do not get Stow packages.
4. Add that package to `STOW_PACKAGES` in `install/stow.sh`.
5. Link the official installation docs in a script comment and in the record's `docs=` field.
6. Update `AGENTS.md` if repository constraints or managed-tool behavior changes.

## Removing a tool

1. Remove its manifest record from `install/manifest.bash`.
2. Remove its installer script if it has one.
3. Remove its config package if it has one.
4. Remove it from `install/stow.sh`.
5. Update `README.md`, `AGENTS.md`, or this file when the change affects them.
