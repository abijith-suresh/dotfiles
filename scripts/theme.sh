#!/usr/bin/env bash
# Repo-backed theme switcher
# Updates tracked config sources inside configs/, then re-stows affected packages.

set -euo pipefail

SELF="$(readlink -f "$0")"
DOTFILES_DIR="$(cd "$(dirname "$SELF")/.." && pwd)"
THEMES_DIR="$DOTFILES_DIR/themes"
CURRENT_THEME_FILE="$THEMES_DIR/current-theme"

# shellcheck disable=SC1091
source "$DOTFILES_DIR/install/lib/ui.sh"
# shellcheck disable=SC1091
source "$DOTFILES_DIR/install/lib/stow.sh"

THEME_NAMES=("Catppuccin" "Tokyo Night" "Nord" "Gruvbox" "Everforest" "Kanagawa" "Rose Pine" "Matte Black" "Osaka Jade" "Ristretto")

to_dir_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g'
}

backup_unmanaged_target() {
  local target="$1"
  local backup="$target.pre-dotfiles-backup"

  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mkdir -p "$(dirname "$backup")"
    mv "$target" "$backup"
    echo "Backed up unmanaged file: $target -> $backup"
  fi
}

prepare_live_targets() {
  backup_unmanaged_target "$HOME/.config/starship.toml"
  backup_unmanaged_target "$HOME/.config/btop/btop.conf"
  backup_unmanaged_target "$HOME/.config/btop/themes/current.theme"
  backup_unmanaged_target "$HOME/.config/zellij/config.kdl"
  backup_unmanaged_target "$HOME/.config/zellij/themes/current.kdl"
  backup_unmanaged_target "$HOME/.config/alacritty/theme.toml"
}

restow_theme_packages() {
  if ! command -v stow >/dev/null 2>&1; then
    echo "stow not found — updated repo files but did not restow live config"
    return 0
  fi

  prepare_live_targets

  (
    cd "$DOTFILES_DIR/configs"
    stow_restow starship
    stow_restow nvim
    stow_restow btop
    stow_restow zellij
    stow_restow alacritty
  )
}

render_zellij_theme() {
  local src="$1"
  local dest="$2"

  awk '
    /^[[:space:]]*themes[[:space:]]*\{/ { in_themes = 1; print; next }
    in_themes && !renamed && /^[[:space:]]*[[:alnum:]_.-]+[[:space:]]*\{$/ {
      sub(/[[:alnum:]_.-]+[[:space:]]*\{/, "current {")
      renamed = 1
      in_themes = 0
      print
      next
    }
    { print }
  ' "$src" > "$dest"
}

apply_theme() {
  local theme_name="$1"
  local theme_dir="$THEMES_DIR/$theme_name"

  if [ ! -d "$theme_dir" ]; then
    echo "Theme not found: $theme_name"
    return 1
  fi

  echo "$theme_name" > "$CURRENT_THEME_FILE"

  # Starship
  cp "$theme_dir/starship.toml" "$DOTFILES_DIR/configs/starship/.config/starship.toml"

  # Neovim
  mkdir -p "$DOTFILES_DIR/configs/nvim/.config/nvim/lua/plugins"
  cp "$theme_dir/neovim.lua" "$DOTFILES_DIR/configs/nvim/.config/nvim/lua/plugins/theme.lua"

  # btop
  mkdir -p "$DOTFILES_DIR/configs/btop/.config/btop/themes"
  cp "$theme_dir/btop.theme" "$DOTFILES_DIR/configs/btop/.config/btop/themes/current.theme"

  # Zellij
  mkdir -p "$DOTFILES_DIR/configs/zellij/.config/zellij/themes"
  render_zellij_theme "$theme_dir/zellij.kdl" "$DOTFILES_DIR/configs/zellij/.config/zellij/themes/current.kdl"

  # Alacritty
  mkdir -p "$DOTFILES_DIR/configs/alacritty/.config/alacritty"
  cp "$theme_dir/alacritty.toml" "$DOTFILES_DIR/configs/alacritty/.config/alacritty/theme.toml"

  restow_theme_packages

  echo "Applied theme: $theme_name"
  echo "Repo-backed theme state updated in configs/ and themes/current-theme"
}

if [ -n "${1:-}" ]; then
  apply_theme "$(to_dir_name "$1")"
  exit 0
fi

if ! command -v gum >/dev/null 2>&1; then
  echo "gum is required for interactive theme selection"
  echo "Available themes:"
  for name in "${THEME_NAMES[@]}"; do
    echo "  - $(to_dir_name "$name")"
  done
  exit 1
fi

selected=$(gum choose "${THEME_NAMES[@]}" --header "Choose your theme")
[ -z "$selected" ] && exit 0
apply_theme "$(to_dir_name "$selected")"
