#!/usr/bin/env bash
# AI Skills Management Script
# Source of truth for always-installed skills

set -e

SELF="$(readlink -f "$0")"
DOTFILES_DIR="$(cd "$(dirname "$SELF")/.." && pwd)"

# shellcheck disable=SC1091
source "$DOTFILES_DIR/install/lib/ui.sh"

# ── Skills list ───────────────────────────────────────────────────────────────
# Format: "owner/repo"

SKILLS=(
  # Personal skills
  "abijith-suresh/skills"

  # Essential community skills
  "vercel-labs/agent-skills"
  "anthropics/skills"
  "vercel-labs/agent-browser"
)

# ── Commands ──────────────────────────────────────────────────────────────────

show_help() {
  if command -v gum >/dev/null 2>&1; then
    gum style \
      --border rounded \
      --border-foreground "$UI_BLUE" \
      --padding "0 2" \
      "$(gum style --foreground "$UI_BLUE" --bold "  AI Skills Manager")" \
      "" \
      "$(printf '%s  Usage: %s{install|update|status|list|sync}%s' "$_UI_MUTED" "$_UI_ACCENT" "$_UI_RST")" \
      "" \
      "$(printf '%s  install%s   Install/update all tracked skills' "$_UI_ACCENT" "$_UI_RST")" \
      "$(printf '%s  update%s    Update all installed skills to latest' "$_UI_ACCENT" "$_UI_RST")" \
      "$(printf '%s  status%s    Show installed vs tracked' "$_UI_ACCENT" "$_UI_RST")" \
      "$(printf '%s  list%s      Print the tracked skills list' "$_UI_ACCENT" "$_UI_RST")" \
      "$(printf '%s  sync%s      Install missing, update existing' "$_UI_ACCENT" "$_UI_RST")"
    echo ""
  else
    cat << EOF
AI Skills Manager

Usage: $(basename "$0") {install|update|status|list|sync}

  install   Install/update all skills in the tracked list
  update    Update all installed skills to latest
  status    Check which skills are installed
  list      Show the tracked skills list
  sync      Install missing skills, update existing ones
EOF
  fi
}

install_skills() {
  ui_section "Installing skills"
  for skill in "${SKILLS[@]}"; do
    ui_log info "Installing $skill"
    bunx skills add "$skill" --yes --global
    ui_ok "$skill"
  done
  ui_banner_success "All skills installed"
}

update_skills() {
  ui_section "Updating skills"
  if command -v gum >/dev/null 2>&1; then
    gum spin --spinner globe --title "Updating all skills..." --show-error -- \
      bunx skills update
  else
    bunx skills update
  fi
  ui_banner_success "Skills updated"
}

show_status() {
  ui_section "Skills Status"

  ui_log info "Installed skills:"
  bunx skills list -g || ui_info "(no skills installed)"

  echo ""
  ui_log info "Tracked in script:"
  for skill in "${SKILLS[@]}"; do
    printf '%s     • %s%s\n' "$_UI_MUTED" "$skill" "$_UI_RST"
  done
}

show_list() {
  ui_section "Tracked Skills"
  for skill in "${SKILLS[@]}"; do
    printf '%s     • %s%s\n' "$_UI_MUTED" "$skill" "$_UI_RST"
  done
}

sync_skills() {
  ui_section "Syncing skills"
  for skill in "${SKILLS[@]}"; do
    ui_log info "Ensuring $skill"
    bunx skills add "$skill" --yes --global 2>/dev/null \
      || bunx skills update "$skill" 2>/dev/null \
      || true
    ui_ok "$skill"
  done
  ui_banner_success "Sync complete"
}

# ── Entrypoint ────────────────────────────────────────────────────────────────

case "${1:-}" in
  install)         install_skills ;;
  update)          update_skills ;;
  status)          show_status ;;
  list)            show_list ;;
  sync)            sync_skills ;;
  help|--help|-h|"") show_help ;;
  *)
    ui_error "Unknown command: $1"
    show_help
    exit 1
    ;;
esac
