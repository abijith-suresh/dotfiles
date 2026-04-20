#!/usr/bin/env bash
# Full dotfiles setup excluding languages

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/common.sh"

ui_section "Running full setup"

run_named_script "[1/3] Base setup"     "$install_dir/categories/base-setup.sh"
run_named_script "[2/3] Terminal tools" "$install_dir/categories/terminal-tools.sh"
run_named_script "[3/3] Coding agents"  "$install_dir/categories/coding-agents.sh"

ui_banner_success "Install Everything complete" "3 categories · base · terminal · agents"
