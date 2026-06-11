#!/usr/bin/env bash
set -euo pipefail

mise use --global go@latest 2>/dev/null || true
echo "Go installed via mise"
