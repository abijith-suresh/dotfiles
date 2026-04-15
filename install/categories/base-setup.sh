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
for script in \
  "$install_dir/tools/app-bin.sh" \
  "$install_dir/tools/app-bash.sh" \
  "$install_dir/tools/app-git.sh" \
  "$install_dir/tools/app-bat.sh" \
  "$install_dir/tools/app-eza.sh" \
  "$install_dir/tools/app-zoxide.sh" \
  "$install_dir/tools/app-starship.sh" \
  "$install_dir/tools/app-mise.sh" \
  "$install_dir/tools/app-zsh.sh"; do
  run_script "$script"
done

ok "Base setup complete"
