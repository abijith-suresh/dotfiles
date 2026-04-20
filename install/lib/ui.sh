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
