#!/usr/bin/env bash
set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/mise.sh"

ensure_mise_tool "rust@stable"
echo "Rust installed via mise"
