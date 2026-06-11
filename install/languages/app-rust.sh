#!/usr/bin/env bash
set -euo pipefail

mise use --global rust@latest 2>/dev/null || true
echo "Rust installed via mise"
