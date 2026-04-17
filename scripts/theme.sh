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

restow_theme_packages() {
  if ! command -v stow >/dev/null 2>&1; then
    ui_warn "stow not found — updated repo files but did not restow live config"
    return 0
  fi

  prepare_stow_packages "$DOTFILES_DIR" starship nvim btop zellij alacritty

  (
    cd "$DOTFILES_DIR/configs"
    stow_restow starship && ui_ok "Stowed starship"
    stow_restow nvim     && ui_ok "Stowed nvim"
    stow_restow btop     && ui_ok "Stowed btop"
    stow_restow zellij   && ui_ok "Stowed zellij"
    stow_restow alacritty && ui_ok "Stowed alacritty"
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
    ui_error "Theme not found: $theme_name"
    return 1
  fi

  ui_section "Applying theme: $theme_name"

  echo "$theme_name" > "$CURRENT_THEME_FILE"
  ui_ok "Updated themes/current-theme"

  # Starship
  cp "$theme_dir/starship.toml" "$DOTFILES_DIR/configs/starship/.config/starship.toml"
  ui_ok "starship.toml"

  # Neovim
  mkdir -p "$DOTFILES_DIR/configs/nvim/.config/nvim/lua/plugins"
  cp "$theme_dir/neovim.lua" "$DOTFILES_DIR/configs/nvim/.config/nvim/lua/plugins/theme.lua"
  ui_ok "nvim theme.lua"

  # btop
  mkdir -p "$DOTFILES_DIR/configs/btop/.config/btop/themes"
  cp "$theme_dir/btop.theme" "$DOTFILES_DIR/configs/btop/.config/btop/themes/current.theme"
  ui_ok "btop current.theme"

  # Zellij
  mkdir -p "$DOTFILES_DIR/configs/zellij/.config/zellij/themes"
  render_zellij_theme "$theme_dir/zellij.kdl" "$DOTFILES_DIR/configs/zellij/.config/zellij/themes/current.kdl"
  ui_ok "zellij current.kdl"

  # Alacritty
  mkdir -p "$DOTFILES_DIR/configs/alacritty/.config/alacritty"
  cp "$theme_dir/alacritty.toml" "$DOTFILES_DIR/configs/alacritty/.config/alacritty/theme.toml"
  ui_ok "alacritty theme.toml"

  ui_section "Restowing packages"
  restow_theme_packages

  ui_banner_success "Theme applied: $theme_name" "configs updated · packages restowed"
}

# ── Entrypoint ────────────────────────────────────────────────────────────────

if [ -n "${1:-}" ]; then
  apply_theme "$(to_dir_name "$1")"
  exit 0
fi

# Interactive: show swatch picker, then apply
selected="$(ui_swatch_picker)"
[ -z "$selected" ] && exit 0
apply_theme "$(to_dir_name "$selected")"
