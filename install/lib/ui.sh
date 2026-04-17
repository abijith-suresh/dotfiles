#!/usr/bin/env bash
# UI helpers — Catppuccin Mocha themed, gum-powered with plain-text fallbacks
# Sourced by common.sh and any script that needs interactive UI.

# Guard against double-sourcing
[[ -n "${_UI_SH_LOADED:-}" ]] && return 0
readonly _UI_SH_LOADED=1

# ── Palette (hex — used for GUM_* env vars) ───────────────────────────────────

UI_ACCENT="#cba6f7"  # mauve    — cursor, selected, accent borders
UI_BLUE="#89b4fa"    # blue     — section headings, sub-headers
UI_GREEN="#a6e3a1"   # green    — success, ok
UI_YELLOW="#f9e2af"  # yellow   — warnings
UI_RED="#f38ba8"     # red      — errors, failures
UI_MUTED="#6c7086"   # overlay0 — secondary text, hints
UI_BORDER="#585b70"  # surface2 — panel outlines

# ANSI 24-bit sequences — precomputed for zero-subprocess status messages
# Format: \e[38;2;R;G;Bm (fg)   \e[48;2;R;G;Bm (bg)
_UI_RST=$'\e[0m'
_UI_BOLD=$'\e[1m'
_UI_DIM=$'\e[2m'
_UI_ITALIC=$'\e[3m'
_UI_ACCENT=$'\e[38;2;203;166;247m'  # #cba6f7
_UI_BLUE=$'\e[38;2;137;180;250m'    # #89b4fa
_UI_GREEN=$'\e[38;2;166;227;161m'   # #a6e3a1
_UI_YELLOW=$'\e[38;2;249;226;175m'  # #f9e2af
_UI_RED=$'\e[38;2;243;139;168m'     # #f38ba8
_UI_MUTED=$'\e[38;2;108;112;134m'   # #6c7086
_UI_BORDER=$'\e[38;2;88;91;112m'    # #585b70

# ── GUM environment defaults ──────────────────────────────────────────────────
# Set once here — every downstream gum call inherits the palette automatically.

export GUM_CHOOSE_CURSOR_FOREGROUND="$UI_ACCENT"
export GUM_CHOOSE_HEADER_FOREGROUND="$UI_BLUE"
export GUM_CHOOSE_SELECTED_FOREGROUND="$UI_ACCENT"
export GUM_CHOOSE_CURSOR_PREFIX="▸ "
export GUM_CHOOSE_SELECTED_PREFIX="◆ "
export GUM_CHOOSE_UNSELECTED_PREFIX="◇ "
export GUM_CONFIRM_PROMPT_FOREGROUND="$UI_ACCENT"
export GUM_CONFIRM_SELECTED_BACKGROUND="$UI_ACCENT"
export GUM_CONFIRM_SELECTED_FOREGROUND="#1e1e2e"
export GUM_CONFIRM_UNSELECTED_BACKGROUND="#313244"
export GUM_CONFIRM_UNSELECTED_FOREGROUND="#cdd6f4"
export GUM_SPIN_SPINNER_FOREGROUND="$UI_ACCENT"
export GUM_INPUT_CURSOR_FOREGROUND="$UI_ACCENT"
export GUM_INPUT_PROMPT_FOREGROUND="$UI_BLUE"
# Preserve nested ANSI codes when passed as args to gum style
export GUM_STYLE_STRIP_ANSI=false

# ── Header ────────────────────────────────────────────────────────────────────

ui_header() {
  if command -v gum >/dev/null 2>&1; then
    echo ""
    gum style \
      --border double \
      --border-foreground "$UI_ACCENT" \
      --align center \
      --padding "1 6" \
      "$(gum style --foreground "$UI_ACCENT" --bold 'd o t f i l e s')" \
      "$(gum style --foreground "$UI_MUTED" --italic 'your machine, your rules')"
    echo ""
  else
    cat << 'EOF'

  ╭─────────────────────────────────────╮
  │         d o t f i l e s             │
  ╰─────────────────────────────────────╯

EOF
  fi
}

# ── Section divider ───────────────────────────────────────────────────────────

ui_section() {
  echo ""
  if command -v gum >/dev/null 2>&1; then
    gum style --foreground "$UI_BLUE" --bold "── $* ──────────────────────────────────────"
  else
    printf '==> %s\n' "$*"
  fi
  echo ""
}

# ── Status messages ───────────────────────────────────────────────────────────
# Raw ANSI — no subprocess overhead, safe to call many times per install.

ui_ok() {
  printf '%s  ✓  %s%s\n' "$_UI_GREEN" "$*" "$_UI_RST"
}

ui_warn() {
  printf '%s  ⚠  %s%s\n' "$_UI_YELLOW" "$*" "$_UI_RST"
}

ui_error() {
  printf '%s  ✗  %s%s\n' "$_UI_RED" "$*" "$_UI_RST" >&2
}

ui_info() {
  printf '%s     %s%s\n' "$_UI_MUTED" "$*" "$_UI_RST"
}

# ── Structured log (gum log) ──────────────────────────────────────────────────
# Levelled output for scripts that emit multiple structured messages
# (update, ai-skills). Level: debug | info | warn | error

ui_log() {
  local level="${1:-info}"
  shift
  if command -v gum >/dev/null 2>&1; then
    gum log --level "$level" -- "$@"
  else
    printf '[%s] %s\n' "$level" "$*"
  fi
}

# ── Completion banner ─────────────────────────────────────────────────────────

ui_banner_success() {
  local title="$1"
  local subtitle="${2:-}"
  echo ""
  if command -v gum >/dev/null 2>&1; then
    if [ -n "$subtitle" ]; then
      gum style \
        --border rounded \
        --border-foreground "$UI_GREEN" \
        --padding "0 2" \
        --align center \
        "$(gum style --foreground "$UI_GREEN" --bold "✓  $title")" \
        "$(gum style --foreground "$UI_MUTED" --italic "$subtitle")"
    else
      gum style \
        --border rounded \
        --border-foreground "$UI_GREEN" \
        --padding "0 2" \
        --align center \
        "$(gum style --foreground "$UI_GREEN" --bold "✓  $title")"
    fi
  else
    printf '  ✓  %s\n' "$title"
    [ -n "$subtitle" ] && printf '     %s\n' "$subtitle"
  fi
  echo ""
}

# ── Swatch helpers ────────────────────────────────────────────────────────────

# Output a 3-wide coloured block using ANSI 24-bit background.
# Arg: hex colour string (with or without leading #)
ui_color_block() {
  local hex="${1#'#'}"
  printf '\033[48;2;%d;%d;%dm   \033[0m' \
    $((16#${hex:0:2})) \
    $((16#${hex:2:2})) \
    $((16#${hex:4:2}))
}

# Print one theme swatch row: coloured name + 5 colour blocks.
# Args: name accent c1 c2 c3 c4 c5
ui_swatch_row() {
  local name="$1" accent="$2"
  local c1="$3" c2="$4" c3="$5" c4="$6" c5="$7"
  local padded
  padded="$(printf '%-14s' "$name")"
  local hex="${accent#'#'}"
  printf '  \033[38;2;%d;%d;%dm%s\033[0m %s%s%s%s%s\n' \
    $((16#${hex:0:2})) $((16#${hex:2:2})) $((16#${hex:4:2})) \
    "$padded" \
    "$(ui_color_block "$c1")" \
    "$(ui_color_block "$c2")" \
    "$(ui_color_block "$c3")" \
    "$(ui_color_block "$c4")" \
    "$(ui_color_block "$c5")"
}

# Interactive theme picker with live swatch preview above the selection list.
# Prints the chosen theme name to stdout, or returns empty on cancel.
ui_swatch_picker() {
  if ! command -v gum >/dev/null 2>&1; then
    printf '  Available themes:\n'
    printf '    - %s\n' \
      "Catppuccin" "Tokyo Night" "Nord" "Gruvbox" "Everforest" \
      "Kanagawa" "Rose Pine" "Matte Black" "Osaka Jade" "Ristretto"
    return
  fi

  echo ""
  printf '%s%s  Theme Palette Preview%s\n' "$_UI_BOLD" "$_UI_BLUE" "$_UI_RST"
  printf '%s  ──────────────────────────────────────%s\n' "$_UI_BORDER" "$_UI_RST"
  echo ""

  # Columns: name | accent | bg | red | green | yellow | accent2
  ui_swatch_row "Catppuccin"  "#cba6f7" "#24273a" "#f38ba8" "#a6e3a1" "#f9e2af" "#89b4fa"
  ui_swatch_row "Tokyo Night" "#7aa2f7" "#1a1b26" "#f7768e" "#9ece6a" "#e0af68" "#ad8ee6"
  ui_swatch_row "Nord"        "#81a1c1" "#2e3440" "#bf616a" "#a3be8c" "#ebcb8b" "#b48ead"
  ui_swatch_row "Gruvbox"     "#d8a657" "#282828" "#ea6962" "#a9b665" "#d8a657" "#7daea3"
  ui_swatch_row "Everforest"  "#a7c080" "#2d353b" "#e67e80" "#a7c080" "#dbbc7f" "#7fbbb3"
  ui_swatch_row "Kanagawa"    "#7e9cd8" "#1f1f28" "#c34043" "#76946a" "#c0a36e" "#957fb8"
  ui_swatch_row "Rose Pine"   "#907aa9" "#faf4ed" "#d7827e" "#56949f" "#ea9d34" "#286983"
  ui_swatch_row "Matte Black" "#bebebe" "#121212" "#D35F5F" "#FFC107" "#e68e0d" "#bebebe"
  ui_swatch_row "Osaka Jade"  "#549e6a" "#111c18" "#FF5345" "#549e6a" "#459451" "#2DD5B7"
  ui_swatch_row "Ristretto"   "#fd6883" "#2c2525" "#fd6883" "#adda78" "#f9cc6c" "#a8a9eb"

  echo ""
  printf '%s  ──────────────────────────────────────%s\n' "$_UI_BORDER" "$_UI_RST"
  echo ""

  gum choose \
    "Catppuccin" "Tokyo Night" "Nord" "Gruvbox" "Everforest" \
    "Kanagawa" "Rose Pine" "Matte Black" "Osaka Jade" "Ristretto" \
    --header "  Select a theme" \
    --height 12
}

# ── Interactive helpers ───────────────────────────────────────────────────────

ui_confirm() {
  local prompt="$1"
  if command -v gum >/dev/null 2>&1; then
    gum confirm "$prompt"
  else
    read -r -p "$prompt [y/N] " reply
    [[ "$reply" =~ ^[Yy]$ ]]
  fi
}

ui_choose_one() {
  local header="$1"
  shift
  if command -v gum >/dev/null 2>&1; then
    gum choose "$@" --header "$header"
  else
    printf '%s\n' "$header" >&2
    printf '%s\n' "$@" >&2
    printf '%s\n' "$1"
  fi
}

ui_choose_many() {
  local header="$1"
  shift
  if command -v gum >/dev/null 2>&1; then
    gum choose "$@" --no-limit --header "$header"
  else
    printf '%s\n' "$@"
  fi
}
