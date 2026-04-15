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

step "Installing base setup"
run_named_script "[1/9] Stowing dotfiles CLI" "$install_dir/tools/app-bin.sh"
run_named_script "[2/9] Applying bash config" "$install_dir/tools/app-bash.sh"
run_named_script "[3/9] Installing git + config" "$install_dir/tools/app-git.sh"
run_named_script "[4/9] Installing bat + config" "$install_dir/tools/app-bat.sh"
run_named_script "[5/9] Installing eza" "$install_dir/tools/app-eza.sh"
run_named_script "[6/9] Installing zoxide" "$install_dir/tools/app-zoxide.sh"
run_named_script "[7/9] Installing starship + config" "$install_dir/tools/app-starship.sh"
run_named_script "[8/9] Installing mise" "$install_dir/tools/app-mise.sh"
run_named_script "[9/9] Installing zsh + config" "$install_dir/tools/app-zsh.sh"

ok "Base setup complete"
