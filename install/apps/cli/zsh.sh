#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: package-manager zsh only; plugins are installed explicitly by zsh-plugins.sh.
pkg_install zsh

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
