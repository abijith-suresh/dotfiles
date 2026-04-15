#!/usr/bin/env bash
# Full dotfiles setup excluding languages

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/common.sh"

run_script "$install_dir/categories/base-setup.sh"
run_script "$install_dir/categories/terminal-tools.sh"
run_script "$install_dir/categories/coding-agents.sh"
run_script "$(cd "$install_dir/.." && pwd)/scripts/theme.sh" catppuccin

ok "Install everything complete"
