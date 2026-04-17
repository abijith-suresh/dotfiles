#!/usr/bin/env bash
# Install terminal tooling and matching configs

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/common.sh"

ensure_sudo_access

ui_section "Installing terminal tools"
TOTAL=13
STEP=0
run_step() {
  STEP=$((STEP + 1))
  run_named_script "[$STEP/$TOTAL] $1" "$2"
}

export DOTFILES_SPINNER=moon
run_step "Installing alacritty config" "$install_dir/tools/app-alacritty.sh"
run_step "Installing btop + config" "$install_dir/tools/app-btop.sh"
run_step "Installing fastfetch + config" "$install_dir/tools/app-fastfetch.sh"
run_step "Installing fd" "$install_dir/tools/app-fd.sh"
export DOTFILES_SPINNER=globe
run_step "Installing fzf + config" "$install_dir/tools/app-fzf.sh"
run_step "Installing GitHub CLI" "$install_dir/tools/app-gh.sh"
run_step "Installing lazygit" "$install_dir/tools/app-lazygit.sh"
run_step "Installing lazydocker" "$install_dir/tools/app-lazydocker.sh"
run_step "Installing neovim + config" "$install_dir/tools/app-neovim.sh"
export DOTFILES_SPINNER=moon
run_step "Installing ripgrep + config" "$install_dir/tools/app-ripgrep.sh"
run_step "Installing tmux + config" "$install_dir/tools/app-tmux.sh"
run_step "Installing vim + config" "$install_dir/tools/app-vim.sh"
run_step "Installing zellij + config" "$install_dir/tools/app-zellij.sh"

ui_banner_success "Terminal tools complete" "13 tools installed and configured"
