#!/usr/bin/env bash
# scripts/theme.sh — Interactive theme switcher
# Switches all tools to a consistent color theme
# Usage: theme.sh [theme-name]
#   With no args: interactive gum menu
#   With args: switch directly to that theme

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
THEMES_DIR="$DOTFILES_DIR/themes"

# Available themes
THEME_NAMES=("Catppuccin" "Tokyo Night" "Nord" "Gruvbox" "Everforest" "Kanagawa" "Rose Pine" "Matte Black" "Osaka Jade" "Ristretto")

# Convert display name to directory name
to_dir_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g'
}

# Apply a theme across all tools
apply_theme() {
  local theme_dir="$1"
  local theme_name="$2"

  if [ ! -d "$theme_dir" ]; then
    echo "Error: Theme '$theme_name' not found at $theme_dir"
    return 1
  fi

  echo "Applying theme: $theme_name"

  # Zellij — copy theme and update config
  if [ -f "$theme_dir/zellij.kdl" ]; then
    mkdir -p ~/.config/zellij/themes
    cp "$theme_dir/zellij.kdl" ~/.config/zellij/themes/
    # Extract theme block name from the kdl file
    local zellij_theme
    zellij_theme=$(grep -oP 'themes\s*\{\s*\K[^{]+' "$theme_dir/zellij.kdl" | head -1 | tr -d ' ')
    if [ -n "$zellij_theme" ]; then
      sed -i "s/theme \".*\"/theme \"$zellij_theme\"/" ~/.config/zellij/config.kdl 2>/dev/null || true
    fi
    echo "  ✓ zellij"
  fi

  # btop — copy theme and update config
  if [ -f "$theme_dir/btop.theme" ]; then
    mkdir -p ~/.config/btop/themes
    local btop_theme_name
    btop_theme_name=$(to_dir_name "$theme_name")
    # Derive the btop theme name from the file content if possible, else use dir name
    local btop_file_theme
    btop_file_theme=$(basename "$theme_dir/btop.theme" .theme)
    cp "$theme_dir/btop.theme" "$HOME/.config/btop/themes/${btop_theme_name}.theme"
    sed -i "s/color_theme = \".*\"/color_theme = \"${btop_theme_name}\"/" ~/.config/btop/btop.conf 2>/dev/null || true
    echo "  ✓ btop"
  fi

  # Neovim — copy theme override
  if [ -f "$theme_dir/neovim.lua" ]; then
    mkdir -p ~/.config/nvim/lua/plugins
    cp "$theme_dir/neovim.lua" ~/.config/nvim/lua/plugins/theme.lua
    echo "  ✓ neovim"
  fi

  # Starship — copy prompt config
  if [ -f "$theme_dir/starship.toml" ]; then
    cp "$theme_dir/starship.toml" ~/.config/starship.toml
    echo "  ✓ starship"
  fi

  # Alacritty — copy terminal theme (for future use)
  if [ -f "$theme_dir/alacritty.toml" ]; then
    mkdir -p ~/.config/alacritty
    cp "$theme_dir/alacritty.toml" ~/.config/alacritty/theme.toml
    echo "  ✓ alacritty"
  fi

  echo ""
  echo "Theme applied! Restart your terminal or reload your shell for full effect."
}

# Main
if [ -n "$1" ]; then
  # Direct theme name provided
  theme_dir_name=$(to_dir_name "$1")
  apply_theme "$THEMES_DIR/$theme_dir_name" "$1"
else
  # Interactive menu
  if ! command -v gum &>/dev/null; then
    echo "Error: gum is required for interactive theme selection."
    echo "Install it: sudo apt install gum"
    echo ""
    echo "Available themes:"
    for name in "${THEME_NAMES[@]}"; do
      echo "  - $(to_dir_name "$name")"
    done
    echo ""
    echo "Usage: theme.sh <theme-name>"
    exit 1
  fi

  THEME=$(gum choose "${THEME_NAMES[@]}" --height 12 --header "Choose your theme")
  if [ -n "$THEME" ]; then
    theme_dir_name=$(to_dir_name "$THEME")
    apply_theme "$THEMES_DIR/$theme_dir_name" "$THEME"
  fi
fi
