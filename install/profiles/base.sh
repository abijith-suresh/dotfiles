#!/usr/bin/env bash
# Common profile orchestration shared by Linux/WSL installs

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"
dotfiles_dir="$(cd "$install_dir/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/common.sh"
# shellcheck disable=SC1091
source "$install_dir/lib/stow.sh"
# shellcheck disable=SC1091
source "$install_dir/lib/ui.sh"

step "Installing required UI dependency"
run_script "$install_dir/tools/app-gum.sh"

step "Installing core CLI tools"
run_script "$install_dir/tools/app-core-cli.sh"
run_script "$install_dir/tools/app-btop.sh"
run_script "$install_dir/tools/app-fd.sh"
run_script "$install_dir/tools/app-fzf.sh"
run_script "$install_dir/tools/app-gh.sh"
run_script "$install_dir/tools/app-lazygit.sh"
run_script "$install_dir/tools/app-lazydocker.sh"
run_script "$install_dir/tools/app-mise.sh"
run_script "$install_dir/tools/app-neovim.sh"
run_script "$install_dir/tools/app-tmux.sh"
run_script "$install_dir/tools/app-zellij.sh"
run_script "$install_dir/tools/app-zsh.sh"

step "Creating XDG directories"
for dir in \
  "$HOME/.config" \
  "$HOME/.local/bin" \
  "$HOME/.local/share" \
  "$HOME/.local/state" \
  "$HOME/.local/state/zsh" \
  "$HOME/.cache"; do
  ensure_dir "$dir"
  ok "Ready $dir"
done

step "Stowing config packages"
stow_packages "$dotfiles_dir" \
  alacritty \
  bash \
  bat \
  bin \
  btop \
  fastfetch \
  fzf \
  git \
  nvim \
  ripgrep \
  starship \
  tmux \
  vim \
  zellij \
  zsh

if ui_confirm "Install coding agents?"; then
  step "Installing coding agents"
  run_script "$install_dir/agents/all.sh"
fi

if command_exists mise && ui_confirm "Set up programming languages?"; then
  step "Selecting programming languages"
  run_script "$install_dir/languages/select.sh"
fi

step "Applying default theme"
run_script "$dotfiles_dir/scripts/theme.sh" catppuccin

ok "Base profile complete"
