#!/usr/bin/env bash
set -euo pipefail

if command -v opencode >/dev/null 2>&1; then
  echo "opencode already installed"
  exit 0
fi

curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path
