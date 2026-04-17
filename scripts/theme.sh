#!/usr/bin/env bash
# Repo-backed theme switcher
# Updates tracked config sources inside configs/, then re-stows affected packages.

set -euo pipefail

SELF="$(readlink -f "$0")"
DOTFILES_DIR="$(cd "$(dirname "$SELF")/.." && pwd)"
THEMES_DIR="$DOTFILES_DIR/themes"
TEMPLATES_DIR="$THEMES_DIR/templates"
CURRENT_THEME_FILE="$THEMES_DIR/current-theme"

# shellcheck disable=SC1091
source "$DOTFILES_DIR/install/lib/ui.sh"
# shellcheck disable=SC1091
source "$DOTFILES_DIR/install/lib/stow.sh"

THEME_NAMES=("Catppuccin" "Tokyo Night" "Nord" "Gruvbox" "Everforest" "Kanagawa" "Rose Pine" "Matte Black" "Osaka Jade" "Ristretto")


to_dir_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g'
}

render_templates() {
  local theme_name="$1"
  local colors_file="$THEMES_DIR/$theme_name/colors.toml"

  if [ ! -f "$colors_file" ]; then
    ui_error "Missing theme definition: $colors_file"
    return 1
  fi

  python3 - "$colors_file" "$TEMPLATES_DIR" "$DOTFILES_DIR" <<'PY'
from __future__ import annotations

import re
import sys
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError as exc:  # pragma: no cover
    raise SystemExit(f"python3 with tomllib is required: {exc}")

colors_file = Path(sys.argv[1])
templates_dir = Path(sys.argv[2])
dotfiles_dir = Path(sys.argv[3])

with colors_file.open("rb") as fh:
    data = tomllib.load(fh)


def flatten(obj, prefix=""):
    out = {}
    if isinstance(obj, dict):
        for key, value in obj.items():
            next_prefix = f"{prefix}{key}" if not prefix else f"{prefix}_{key}"
            out.update(flatten(value, next_prefix))
    else:
        out[prefix] = obj
    return out


values = flatten(data)


def as_text(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value)


conditional_re = re.compile(r"\{\{#if\s+([A-Za-z0-9_]+)\s*\}\}(.*?)\{\{/if\}\}", re.S)
placeholder_re = re.compile(r"\{\{\s*([A-Za-z0-9_]+)\s*\}\}")


def truthy(key: str) -> bool:
    value = values.get(key)
    if value is None:
        return False
    if isinstance(value, bool):
        return value
    return str(value) != ""



def hex_to_rgb(value: str) -> str:
    stripped = value.lstrip("#")
    if len(stripped) != 6:
        return value
    return f"{int(stripped[0:2], 16)},{int(stripped[2:4], 16)},{int(stripped[4:6], 16)}"



def render(template: str) -> str:
    previous = None
    while previous != template:
        previous = template
        template = conditional_re.sub(
            lambda match: render(match.group(2)) if truthy(match.group(1)) else "",
            template,
        )

    def replace(match):
        key = match.group(1)
        if key.endswith("_strip"):
            base_key = key[:-6]
            value = values.get(base_key, "")
            return as_text(value).lstrip("#")
        if key.endswith("_rgb"):
            base_key = key[:-4]
            value = values.get(base_key, "")
            return hex_to_rgb(as_text(value))
        return as_text(values.get(key, match.group(0)))

    return placeholder_re.sub(replace, template)


outputs = {
    "starship.toml": dotfiles_dir / "configs/starship/.config/starship.toml",
    "neovim.lua": dotfiles_dir / "configs/nvim/.config/nvim/lua/plugins/theme.lua",
    "btop.theme": dotfiles_dir / "configs/btop/.config/btop/themes/current.theme",
    "zellij.kdl": dotfiles_dir / "configs/zellij/.config/zellij/themes/current.kdl",
    "alacritty.toml": dotfiles_dir / "configs/alacritty/.config/alacritty/theme.toml",
}

for template_path in sorted(templates_dir.glob("*.tpl")):
    target_name = template_path.stem
    destination = outputs.get(target_name)
    if destination is None:
        continue

    rendered = render(template_path.read_text())
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(rendered.rstrip() + "\n")
PY

  ui_ok "Rendered templates from colors.toml"
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
    stow_restow nvim && ui_ok "Stowed nvim"
    stow_restow btop && ui_ok "Stowed btop"
    stow_restow zellij && ui_ok "Stowed zellij"
    stow_restow alacritty && ui_ok "Stowed alacritty"
  )
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

  render_templates "$theme_name"

  ui_section "Restowing packages"
  restow_theme_packages

  ui_banner_success "Theme applied: $theme_name" "configs updated · packages restowed"
}

# ── Entrypoint ────────────────────────────────────────────────────────────────

if [ -n "${1:-}" ]; then
  apply_theme "$(to_dir_name "$1")"
  exit 0
fi

selected="$(ui_swatch_picker)"
[ -z "$selected" ] && exit 0
apply_theme "$(to_dir_name "$selected")"
