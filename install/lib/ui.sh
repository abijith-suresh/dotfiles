#!/usr/bin/env bash
# UI helpers with gum fallback

ui_header() {
  cat << 'EOF'

  ╭─────────────────────────────────────╮
  │         d o t f i l e s             │
  ╰─────────────────────────────────────╯

EOF
}

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
    printf "%s\n" "$header" >&2
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
