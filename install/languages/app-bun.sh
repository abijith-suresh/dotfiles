#!/usr/bin/env bash
set -euo pipefail

mise use --global bun@latest 2>/dev/null || true
echo "Bun installed via mise"
