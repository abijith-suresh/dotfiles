#!/usr/bin/env bash
set -euo pipefail

if command -v claude >/dev/null 2>&1; then
  echo "claude already installed"
  exit 0
fi

curl -fsSL https://claude.ai/install.sh | bash
