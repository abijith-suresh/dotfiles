#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: official Antigravity CLI installer, checked 2026-10-20.
# https://www.antigravity.google/docs/cli/install
#
# The bootstrapper accepts only -d/--dir and -h/--help; --skip-aliases and
# --skip-path belong to the native `agy install` handoff. That handoff runs
# unconditionally, so install in a throwaway HOME and copy the binary out to
# keep shell rc files untouched. PATH is owned by the zsh package.
if command -v agy >/dev/null 2>&1; then
  info "antigravity already installed"
  exit 0
fi

tmp_home="$(mktemp -d)"
trap 'rm -rf -- "$tmp_home"' EXIT

curl -fsSL https://antigravity.google/cli/install.sh | HOME="$tmp_home" bash
mkdir -p "$HOME/.local/bin"
install -m 0755 "$tmp_home/.local/bin/agy" "$HOME/.local/bin/agy"
"$HOME/.local/bin/agy" install --skip-aliases --skip-path || true
