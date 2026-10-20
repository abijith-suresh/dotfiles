#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: official Grok CLI installer, checked 2026-10-20.
# https://x.ai/cli
if command -v grok >/dev/null 2>&1; then
  info "grok already installed"
  exit 0
fi

# The installer edits shell rc files when $SHELL is set, so clear it. PATH is
# owned by the zsh package; GROK_BIN_DIR keeps the binary on install.sh's PATH.
curl -fsSL https://x.ai/cli/install.sh |
  SHELL='' GROK_BIN_DIR="$HOME/.local/bin" bash

# Cursor CLI also owns an `agent` command; keep its documented entrypoint.
if cursor_agent="$(command -v cursor-agent)"; then
  ln -sf "$cursor_agent" "$HOME/.local/bin/agent"
fi
