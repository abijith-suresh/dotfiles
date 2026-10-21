#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

failures=0

run_check() {
  local label="$1"
  shift
  printf '==> %s\n' "$label"
  if "$@"; then
    printf '  ok\n'
  else
    printf '  failed\n' >&2
    failures=$((failures + 1))
  fi
}

check_bash() {
  local status=0
  while IFS= read -r -d '' file; do
    bash -n "$file" || status=1
  done < <(find . -type d \( -name .git -o -name node_modules \) -prune -o -type f \( -name '*.sh' -o -name '*.bash' \) -print0)
  return "$status"
}

check_zsh() {
  local status=0
  while IFS= read -r -d '' file; do
    zsh -n "$file" || status=1
  done < <(find configs -type f \( -name '*.zsh' -o -name '.zshrc' -o -name '.zshenv' -o -name '.zsh_aliases' \) -print0)
  return "$status"
}

check_shfmt() {
  command -v shfmt >/dev/null 2>&1 || {
    printf '  shfmt not installed; skipping\n'
    return 0
  }
  shfmt -i 2 -ci -d \
    boot.sh \
    install.sh \
    install \
    scripts
}

check_shellcheck() {
  command -v shellcheck >/dev/null 2>&1 || {
    printf '  shellcheck not installed; skipping\n'
    return 0
  }
  mapfile -d '' files < <(find . -type d \( -name .git -o -name node_modules \) -prune -o -type f \( -name '*.sh' -o -name '*.bash' \) -print0)
  shellcheck "${files[@]}"
}

check_manifest() {
  local status=0
  local app ref need index mine
  local phase

  app_index() {
    local target="$1"
    local i=0
    for ref in "${APP_ORDER[@]}"; do
      if [ "$ref" = "$target" ]; then
        printf '%s\n' "$i"
        return 0
      fi
      i=$((i + 1))
    done
    return 1
  }

  [ "${#APP_ORDER[@]}" -gt 0 ] || {
    printf 'manifest has no apps\n' >&2
    return 1
  }
  [ "${#APP_ORDER[@]}" -eq "$(printf '%s\n' "${APP_ORDER[@]}" | sort -u | wc -l)" ] || {
    printf 'duplicate app in manifest\n' >&2
    status=1
  }

  for app in "${APP_ORDER[@]}"; do
    case "${APP_MODE[$app]:-tolerant}" in
      required | tolerant) ;;
      *)
        printf '%s: mode must be required|tolerant\n' "$app" >&2
        status=1
        ;;
    esac
    case "${APP_SOURCE[$app]:-pkg}" in
      pkg) ;;
      script)
        [ -n "${APP_DOCS[$app]:-}" ] || {
          printf '%s: source=script requires docs=\n' "$app" >&2
          status=1
        }
        local script
        script="$ROOT/install/$(script_rel_for "$app")"
        [ -f "$script" ] || {
          printf '%s: missing script: %s\n' "$app" "$script" >&2
          status=1
        }
        ;;
      *)
        printf '%s: source must be pkg|script\n' "$app" >&2
        status=1
        ;;
    esac
    if [ -n "${APP_NEEDS[$app]:-}" ]; then
      local needs
      IFS=',' read -r -a needs <<<"$(printf '%s' "${APP_NEEDS[$app]}" | tr -d '[:space:]')"
      for need in "${needs[@]}"; do
        [ -n "$need" ] || continue
        if [ -z "${APP_PHASE[$need]+x}" ]; then
          printf '%s: needs unknown app: %s\n' "$app" "$need" >&2
          status=1
          continue
        fi
        if [ "$need" = "$app" ]; then
          printf '%s: needs itself\n' "$app" >&2
          status=1
        fi
        if ! index="$(app_index "$need")"; then
          printf '%s: needs %s which is not scheduled earlier\n' "$app" "$need" >&2
          status=1
          continue
        fi
        mine="$(app_index "$app")"
        [ "$index" -lt "$mine" ] || {
          printf '%s: needs %s which is not scheduled earlier\n' "$app" "$need" >&2
          status=1
        }
      done
    fi
  done

  # Every installer script must be referenced by a scripted record.
  local file rel found script_rel
  while IFS= read -r -d '' file; do
    rel="${file#install/}"
    found=0
    for app in "${APP_ORDER[@]}"; do
      [ "${APP_SOURCE[$app]:-pkg}" = "script" ] || continue
      script_rel="$(script_rel_for "$app")" || script_rel="${APP_SCRIPT[$app]}"
      [ "$script_rel" = "$rel" ] && found=1
    done
    [ "$found" -eq 1 ] || {
      printf 'installer not referenced by any manifest record: %s\n' "$file" >&2
      status=1
    }
  done < <(find install/apps install/languages -type f -name '*.sh' -print0 | sort -z)

  # Phases appear in PHASE_ORDER and each phase is one contiguous block.
  local expect_idx=0 prev=""
  for app in "${APP_ORDER[@]}"; do
    phase="${APP_PHASE[$app]}"
    if [ "$phase" != "$prev" ]; then
      found=0
      for ref in "${PHASE_ORDER[@]}"; do
        [ "$ref" = "$phase" ] && found=1
      done
      if [ "$found" -eq 0 ]; then
        printf 'unknown phase: %s\n' "$phase" >&2
        status=1
      elif [ "$expect_idx" -lt "${#PHASE_ORDER[@]}" ]; then
        ref="${PHASE_ORDER[$expect_idx]}"
        if [ "$ref" != "$phase" ]; then
          printf 'phase order: expected %s, found %s\n' "$ref" "$phase" >&2
          status=1
        fi
        expect_idx=$((expect_idx + 1))
      else
        printf 'phase %s re-enters after the full PHASE_ORDER ran\n' "$phase" >&2
        status=1
      fi
      prev="$phase"
    fi
  done

  [ "$expect_idx" -eq "${#PHASE_ORDER[@]}" ] || {
    printf 'phase blocks must cover PHASE_ORDER exactly once each\n' >&2
    status=1
  }

  return "$status"
}

check_ignore_sync() {
  bash "$ROOT/scripts/sync-ignore.sh" --check
}

check_stow_package_list() {
  local expected actual status
  expected="$(mktemp)"
  actual="$(mktemp)"

  printf '%s\n' "${STOW_PACKAGES[@]}" | sort >"$expected"
  find "$ROOT/configs" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort >"$actual"

  status=0
  diff -u "$expected" "$actual" || status=1
  rm -f "$expected" "$actual"
  return "$status"
}

# One batch dry-run from inside configs/ with an isolated HOME: exercises
# configs/.stowrc ignore rules exactly as the installer does, and catches
# cross-package collisions a per-package loop cannot see. The isolated
# HOME also keeps a user's own ~/.stowrc out of the result.
check_stow_tmp_home() {
  local tmp_home status=0
  tmp_home="$(mktemp -d)"
  (
    cd "$ROOT/configs"
    HOME="$tmp_home" stow --dir . --target "$tmp_home" -n --no-folding "${STOW_PACKAGES[@]}"
  ) >/dev/null || status=1
  rm -rf "$tmp_home"
  return "$status"
}

check_policy() {
  local status=0

  # Never pin a default model, provider, or default model arguments.
  if grep -rIniE '(model|provider)[[:space:]]*[=:]|anthropic|openai|deepseek|qwen|ollama|openrouter|minimax|kimi|gemini' configs/; then
    printf 'config policy: model/provider references must stay out of configs/\n' >&2
    status=1
  fi

  # Catppuccin Mocha everywhere; Neovim may fall back to Latte on light
  # backgrounds (AGENTS.md invariant exception).
  local theme_hits
  theme_hits="$(grep -rIniE 'tokyonight|gruvbox|\bnord\b|one-?dark|rose-?pine|dracula|solarized|everforest|kanagawa|monokai|\blatte\b|frappe|macchiato' configs/ |
    grep -v 'configs/nvim/.config/nvim/lua/plugins/colorscheme.lua' || true)"
  if [ -n "$theme_hits" ]; then
    printf '%s\n' "$theme_hits" >&2
    printf 'config policy: non-Catppuccin-Mocha theme reference\n' >&2
    status=1
  fi

  # Fresh installs must not configure MCP servers.
  if grep -rIn 'mcpServers' configs/; then
    printf 'config policy: MCP configuration must stay out of configs/\n' >&2
    status=1
  fi

  # Agent CLIs are install-only; they keep no Stow package.
  local agent
  for agent in antigravity claude codex copilot cursor grok opencode pi; do
    if [ -d "configs/$agent" ]; then
      printf 'config policy: agent settings package found: configs/%s\n' "$agent" >&2
      status=1
    fi
  done

  return "$status"
}

check_secrets() {
  local status=0
  local file base
  while IFS= read -r file; do
    base="${file##*/}"
    case "$base" in
      auth.json | *.env | .env* | *.key | *.pem | *token* | *secret* | *credential*)
        printf 'tracked secret-shaped file: %s\n' "$file" >&2
        status=1
        ;;
    esac
  done < <(git ls-files)
  if git grep -qInE 'ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY|xox[baprs]-|sk-[A-Za-z0-9_-]{20,}' -- .; then
    git grep -nInE 'ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY|xox[baprs]-|sk-[A-Za-z0-9_-]{20,}' -- . >&2
    printf 'secrets scan: token-shaped string in tracked files\n' >&2
    status=1
  fi
  return "$status"
}

# shellcheck disable=SC1090,SC1091
source "$ROOT/install/lib.sh"
# shellcheck disable=SC1090,SC1091
source "$ROOT/install/manifest.bash"
# shellcheck disable=SC1090,SC1091
source "$ROOT/install/stow.sh"

run_check "bash syntax" check_bash
run_check "zsh syntax" check_zsh
run_check "shfmt" check_shfmt
run_check "shellcheck" check_shellcheck
run_check "manifest consistency" check_manifest
run_check "ignore policy sync" check_ignore_sync
run_check "stow package list" check_stow_package_list
run_check "stow batch dry run" check_stow_tmp_home
run_check "config policy" check_policy
run_check "secrets scan" check_secrets

if [ "$failures" -gt 0 ]; then
  printf '\n%d validation check(s) failed.\n' "$failures" >&2
  exit 1
fi

printf '\nAll validation checks passed.\n'
