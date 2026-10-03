#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Official latest stable CLI-only installer. Do not pass --agents: it configures MCP.
# https://docs.railway.com/cli
# https://github.com/railwayapp/cli/blob/master/install.sh
if command -v railway >/dev/null 2>&1; then
  info "railway already installed"
  exit 0
fi

mkdir -p "$HOME/.local/bin"
path_prepend_local_bin
curl -fsSL https://railway.com/install.sh | bash -s -- -y --bin-dir "$HOME/.local/bin"
