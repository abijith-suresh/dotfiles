#!/usr/bin/env bash
# AI Skills Management Script
# Source of truth for always-installed skills

set -e

# Array of skills to always have installed
# Format: "owner/repo"
SKILLS=(
  # Personal skills
  "abijith-suresh/skills"
  
  # Essential community skills
  "vercel-labs/agent-skills"
  "anthropics/skills"
  "vercel-labs/agent-browser"
)

show_help() {
  cat << EOF
AI Skills Manager

Usage: $(basename "$0") {install|update|status|list}

Commands:
  install    Install/update all skills in the hardcoded list
  update     Update all installed skills to latest
  status     Check which skills are installed
  list       Show the hardcoded skills list
  sync       Install missing skills, update existing ones

Examples:
  $(basename "$0") install    # First time setup
  $(basename "$0") sync       # Daily use - ensures all skills present
EOF
}

install_skills() {
  echo "Installing skills..."
  for skill in "${SKILLS[@]}"; do
    echo "  → $skill"
    bunx skills add "$skill" --yes --global
  done
  echo "✓ All skills installed"
}

update_skills() {
  echo "Updating all skills..."
  bunx skills update
  echo "✓ Skills updated"
}

show_status() {
  echo "Installed skills:"
  bunx skills list -g || echo "  (no skills installed)"
  echo ""
  echo "Tracked in script:"
  for skill in "${SKILLS[@]}"; do
    echo "  • $skill"
  done
}

show_list() {
  echo "Skills tracked in this script:"
  for skill in "${SKILLS[@]}"; do
    echo "  • $skill"
  done
}

sync_skills() {
  echo "Syncing skills..."
  # This installs missing ones and updates existing
  for skill in "${SKILLS[@]}"; do
    echo "  → Ensuring: $skill"
    bunx skills add "$skill" --yes --global 2>/dev/null || bunx skills update "$skill" 2>/dev/null || true
  done
  echo "✓ Sync complete"
}

case "${1:-}" in
  install)
    install_skills
    ;;
  update)
    update_skills
    ;;
  status)
    show_status
    ;;
  list)
    show_list
    ;;
  sync)
    sync_skills
    ;;
  help|--help|-h|"")
    show_help
    ;;
  *)
    echo "Unknown command: $1"
    show_help
    exit 1
    ;;
esac
