#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

# shellcheck disable=SC1090,SC1091
source "$DOTFILES_DIR/install/lib.sh"

FOUNDATION_APPS=(mise zsh git)
CLI_APPS=(
  bat
  btop
  eza
  fastfetch
  fd
  fzf
  gh
  lazydocker
  lazygit
  neovim
  ripgrep
  shellcheck
  shfmt
  starship
  tmux
  vim
  zellij
  zsh-plugins
  zoxide
)
AGENT_APPS=(claude codex copilot opencode pi)
LANGUAGES=(node bun java python go)

run_phase() {
  local label="$1"
  local dir="$2"
  local mode="$3"
  shift 3

  section "$label"
  local item script
  for item in "$@"; do
    script="$DOTFILES_DIR/$dir/$item.sh"
    if [ "$mode" = "required" ]; then
      run_required_script "$item" "$script"
    else
      run_tolerant_script "$item" "$script"
    fi
  done
}

detect_platform
path_prepend_local_bin

section "Detected platform"
ok "$PLATFORM using $PKG_MANAGER"

section "Bootstrapping"
run_required_script "base packages" "$DOTFILES_DIR/install/bootstrap/$PKG_MANAGER.sh"
ensure_xdg_dirs
ok "XDG directories"

run_phase "Foundation" "install/apps/cli" "required" "${FOUNDATION_APPS[@]}"
run_phase "CLI and TUI apps" "install/apps/cli" "tolerant" "${CLI_APPS[@]}"
run_phase "Agent CLIs" "install/apps/agents" "tolerant" "${AGENT_APPS[@]}"
run_phase "Languages and editor tooling" "install/languages" "tolerant" "${LANGUAGES[@]}"

section "Configuration"
# shellcheck disable=SC1090,SC1091
source "$DOTFILES_DIR/install/stow.sh"
stow_all

print_final_summary
