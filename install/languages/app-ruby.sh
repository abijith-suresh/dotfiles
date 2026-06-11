#!/usr/bin/env bash
set -euo pipefail

mise use --global ruby@latest 2>/dev/null || true
echo "Ruby installed via mise"
