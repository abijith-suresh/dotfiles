#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: official stable, self-contained CLI installer; no Node runtime.
# https://github.com/pingdotgg/t3code/blob/main/docs/user/install.md (checked 2026-10-20)
# https://t3.codes/install.sh
# Run: `t3 project add .`, then `t3 serve --host 127.0.0.1`; open the printed
# pairing URL (first connection only, keep it private). `t3 pair` re-pairs.
# The server picks a free port from 3773; `--port` overrides.
# State lives in ~/.t3; T3CODE_HOME or --base-dir relocates it for every command.
# Pairing is separate from agent login: see `t3 auth --help`.
if command -v t3 >/dev/null 2>&1; then
  info "t3 already installed"
  exit 0
fi

curl -fsSL https://t3.codes/install.sh |
  T3CODE_CHANNEL=stable T3CODE_VERSION='' T3CODE_INSTALL_BIN_DIR="$HOME/.local/bin" sh
