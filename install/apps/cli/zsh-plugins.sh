#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: direct upstream git clones, following each plugin's manual install docs.
# https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md
# https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md
plugins_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
mkdir -p "$plugins_dir"

clone_plugin() {
  local name="$1"
  local repo="$2"
  local entrypoint="$3"
  local dir="$plugins_dir/$name"

  if [ -f "$dir/$entrypoint" ]; then
    info "$name already installed"
    return
  fi

  if [ -e "$dir" ]; then
    die "$dir exists but does not contain $entrypoint"
  fi

  git clone --depth=1 "$repo" "$dir"
  [ -f "$dir/$entrypoint" ] || die "$name clone completed but $entrypoint is missing"
}

clone_plugin \
  zsh-autosuggestions \
  https://github.com/zsh-users/zsh-autosuggestions.git \
  zsh-autosuggestions.zsh

clone_plugin \
  zsh-syntax-highlighting \
  https://github.com/zsh-users/zsh-syntax-highlighting.git \
  zsh-syntax-highlighting.zsh
