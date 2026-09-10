#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_home=""
conflict_home=""

cleanup() {
  if [ -n "$test_home" ] && [ -d "$test_home" ]; then
    find "$test_home" -depth -delete
  fi
  if [ -n "$conflict_home" ] && [ -d "$conflict_home" ]; then
    find "$conflict_home" -depth -delete
  fi
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

printf '%s\n' 'Stow deployment, conflict backup, and repeatability passed.'
