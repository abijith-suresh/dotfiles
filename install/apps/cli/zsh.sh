#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: package-manager zsh plus zinit runtime plugin manager.
pkg_install zsh

zinit_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [ -d "$zinit_dir" ]; then
  info "Zinit already installed"
else
  git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$zinit_dir"
fi

zsh_path="$(command -v zsh || true)"
if [ -z "$zsh_path" ]; then
  die "zsh was installed but is not on PATH"
fi

current_shell="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || true)"
if [ "$current_shell" != "$zsh_path" ]; then
  if chsh -s "$zsh_path" "$USER" </dev/null; then
    info "Default shell changed to zsh"
  else
    warn "Could not change default shell automatically. Run: chsh -s $zsh_path"
  fi
else
  info "zsh is already the default shell"
fi
