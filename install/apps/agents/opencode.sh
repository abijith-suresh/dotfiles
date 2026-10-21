#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: official OpenCode v2 installer, checked 2026-10-21.
# https://opencode.ai/v2/docs
#
# v2 installs to ~/.opencode/bin/opencode, which the installer shell's PATH
# does not carry; expose the binary through ~/.local/bin for scripts and the
# end-state verification. PATH in interactive shells is owned by the zsh
# package.
native_bin="$HOME/.opencode/bin/opencode"

if [ ! -x "$native_bin" ]; then
  curl -fsSL https://opencode.ai/v2/install | bash -s -- --no-modify-path
fi

if [ -x "$native_bin" ]; then
  mkdir -p "$HOME/.local/bin"
  ln -sfn "$native_bin" "$HOME/.local/bin/opencode"
else
  warn "opencode installer produced no binary at ~/.opencode/bin/opencode"
fi
