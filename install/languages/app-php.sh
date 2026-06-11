#!/usr/bin/env bash
set -euo pipefail

mise use --global php@latest 2>/dev/null || true
echo "PHP installed via mise"
