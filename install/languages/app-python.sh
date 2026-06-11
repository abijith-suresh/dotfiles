#!/usr/bin/env bash
set -euo pipefail

mise use --global python@latest 2>/dev/null || true
echo "Python installed via mise"
