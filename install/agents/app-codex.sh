#!/usr/bin/env bash
set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/common.sh"
# shellcheck disable=SC1091
source "$install_dir/lib/mise.sh"

install_node_cli "@openai/codex" codex
