#!/usr/bin/env bash
# Install terminal tooling and matching configs

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/common.sh"

step "Installing terminal tools"
for script in \
  "$install_dir/tools/app-alacritty.sh" \
  "$install_dir/tools/app-btop.sh" \
  "$install_dir/tools/app-fastfetch.sh" \
  "$install_dir/tools/app-fd.sh" \
  "$install_dir/tools/app-fzf.sh" \
  "$install_dir/tools/app-gh.sh" \
  "$install_dir/tools/app-lazygit.sh" \
  "$install_dir/tools/app-lazydocker.sh" \
  "$install_dir/tools/app-neovim.sh" \
  "$install_dir/tools/app-ripgrep.sh" \
  "$install_dir/tools/app-tmux.sh" \
  "$install_dir/tools/app-vim.sh" \
  "$install_dir/tools/app-zellij.sh"; do
  run_script "$script"
done

ok "Terminal tools complete"
