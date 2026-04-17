#!/usr/bin/env bash
# Base shell and CLI setup for the current machine

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/common.sh"
# shellcheck disable=SC1091
source "$install_dir/lib/os.sh"

if [ "$(detect_os)" = "wsl" ]; then
  if [ -f /usr/share/zsh/vendor-completions/_docker ]; then
    sudo rm -f /usr/share/zsh/vendor-completions/_docker
  fi
  rm -f "$HOME"/.zcompdump*
fi

ensure_sudo_access

ui_section "Creating XDG directories"
export DOTFILES_SPINNER=dot
for dir in \
  "$HOME/.config" \
  "$HOME/.local/bin" \
  "$HOME/.local/share" \
  "$HOME/.local/state" \
  "$HOME/.local/state/zsh" \
  "$HOME/.cache"; do
  ensure_dir "$dir"
  ui_ok "Ready $dir"
done

ui_section "Installing base setup"
TOTAL=9
STEP=0
run_step() {
  STEP=$((STEP + 1))
  run_named_script "[$STEP/$TOTAL] $1" "$2"
}

export DOTFILES_SPINNER=dot
run_step "Stowing dotfiles CLI" "$install_dir/tools/app-bin.sh"
run_step "Applying bash config" "$install_dir/tools/app-bash.sh"
export DOTFILES_SPINNER=moon
run_step "Installing git + config" "$install_dir/tools/app-git.sh"
run_step "Installing bat + config" "$install_dir/tools/app-bat.sh"
run_step "Installing eza" "$install_dir/tools/app-eza.sh"
run_step "Installing zoxide" "$install_dir/tools/app-zoxide.sh"
export DOTFILES_SPINNER=globe
run_step "Installing starship + config" "$install_dir/tools/app-starship.sh"
run_step "Installing mise" "$install_dir/tools/app-mise.sh"
export DOTFILES_SPINNER=moon
run_step "Installing zsh + config" "$install_dir/tools/app-zsh.sh"

ui_banner_success "Base setup complete" "shell · git · bat · eza · zsh · starship · mise"
