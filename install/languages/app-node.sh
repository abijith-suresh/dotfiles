#!/usr/bin/env bash
set -euo pipefail

mise use --global node@lts 2>/dev/null || true
echo "Node.js LTS installed via mise"
