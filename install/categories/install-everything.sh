#!/usr/bin/env bash
# Full dotfiles setup excluding languages

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"
dotfiles_dir="$(cd "$install_dir/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/common.sh"

step "Running full setup"
run_named_script "[1/4] Base setup" "$install_dir/categories/base-setup.sh"
run_named_script "[2/4] Terminal tools" "$install_dir/categories/terminal-tools.sh"
run_named_script "[3/4] Coding agents" "$install_dir/categories/coding-agents.sh"
run_named_script "[4/4] Applying default theme" "$dotfiles_dir/scripts/theme.sh" catppuccin

ok "Install everything complete"
