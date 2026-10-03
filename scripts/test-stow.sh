#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_home=""
conflict_home=""
seed_home=""

cleanup() {
  local dir
  for dir in "$test_home" "$conflict_home" "$seed_home"; do
    if [ -n "$dir" ] && [ -d "$dir" ]; then
      find "$dir" -depth -delete
    fi
  done
}
trap cleanup EXIT

run_stow() {
  local target_home="$1"
  HOME="$target_home" \
    DOTFILES_DIR="$REPO_DIR" \
    PLATFORM=ubuntu \
    PKG_MANAGER=apt \
    bash "$REPO_DIR/install/stow.sh"
}

test_home="$(mktemp -d /tmp/dotfiles-stow-test.XXXXXX)"
run_stow "$test_home" >/dev/null

[ -L "$test_home/.zshenv" ]
[ "$(readlink -f "$test_home/.zshenv")" = "$REPO_DIR/configs/zsh/.zshenv" ]

run_stow "$test_home" >/dev/null
if find "$test_home" -maxdepth 1 -name '.zshenv.backup*' -print -quit | grep -q .; then
  printf '%s\n' 'unexpected backup after repeated Stow run' >&2
  exit 1
fi

conflict_home="$(mktemp -d /tmp/dotfiles-stow-conflict.XXXXXX)"
touch "$conflict_home/.zshenv"
run_stow "$conflict_home" >/dev/null

[ -f "$conflict_home/.zshenv.backup" ]
[ -L "$conflict_home/.zshenv" ]
[ "$(readlink -f "$conflict_home/.zshenv")" = "$REPO_DIR/configs/zsh/.zshenv" ]

run_seed() {
  local target_home="$1"
  local refresh="${2:-false}"
  HOME="$target_home" \
    DOTFILES_DIR="$REPO_DIR" \
    REFRESH_RUNTIME="$refresh" \
    bash "$REPO_DIR/install/runtime.sh"
}

# Templates are sources for seeding, not Stow packages, and runtime-owned files
# must never be symlinked into the repository.
if find "$test_home" -name '*.template' -print -quit | grep -q .; then
  printf '%s\n' 'Stow deployed a *.template file' >&2
  exit 1
fi
if [ -e "$test_home/.pi/agent/settings.json" ] || [ -L "$test_home/.pi/agent/settings.json" ]; then
  printf '%s\n' 'Stow deployed a runtime-owned file' >&2
  exit 1
fi
if [ -e "$test_home/.codex/config.toml" ] || [ -L "$test_home/.codex/config.toml" ]; then
  printf '%s\n' 'Stow deployed a runtime-owned file' >&2
  exit 1
fi

seed_home="$(mktemp -d /tmp/dotfiles-seed-test.XXXXXX)"

# A leftover Stow symlink is replaced by an owned copy.
mkdir -p "$seed_home/.pi/agent"
ln -s "$REPO_DIR/configs/pi/.pi/agent/settings.json.template" "$seed_home/.pi/agent/settings.json"
run_seed "$seed_home" >/dev/null
[ ! -L "$seed_home/.pi/agent/settings.json" ]
[ -f "$seed_home/.pi/agent/settings.json" ]

# Seeding is idempotent and never clobbers local state.
printf '%s\n' 'local-state' >"$seed_home/.codex/config.toml"
run_seed "$seed_home" >/dev/null
if [ -L "$seed_home/.codex/config.toml" ]; then
  printf '%s\n' 'seeding replaced a regular file with a symlink' >&2
  exit 1
fi
grep -q 'local-state' "$seed_home/.codex/config.toml"

# --refresh-runtime overwrites and keeps a backup.
run_seed "$seed_home" true >/dev/null
if grep -q 'local-state' "$seed_home/.codex/config.toml"; then
  printf '%s\n' 'refresh did not overwrite the live file' >&2
  exit 1
fi
[ -f "$seed_home/.codex/config.toml.backup" ]

printf '%s\n' 'Stow deployment, conflict backup, runtime seeding, and repeatability passed.'
