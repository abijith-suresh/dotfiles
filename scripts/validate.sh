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
  done < <(find . -path './.git' -prune -o -type f \( -name '*.sh' -o -name 'install.sh' -o -name 'boot.sh' \) -print0)
  return "$status"
}

check_zsh() {
  local status=0
  while IFS= read -r -d '' file; do
    zsh -n "$file" || status=1
  done < <(find configs -type f \( -name '*.zsh' -o -name '.zshrc' -o -name '.zshenv' \) -print0)
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
  mapfile -d '' files < <(find . -path './.git' -prune -o -type f \( -name '*.sh' -o -name 'install.sh' -o -name 'boot.sh' \) -print0)
  shellcheck "${files[@]}"
}

check_stow_tmp_home() {
  local tmp_home output
  tmp_home="$(mktemp -d)"

  # shellcheck disable=SC1090,SC1091
  source "$ROOT/install/stow.sh"
  local package
  for package in "${STOW_PACKAGES[@]}"; do
    if ! output="$(stow --dir "$ROOT/configs" --target "$tmp_home" -n -v --no-folding "$package" 2>&1)"; then
      printf '%s\n' "$output" >&2
      rm -rf "$tmp_home"
      return 1
    fi
  done
  rm -rf "$tmp_home"
}

check_stow_package_list() {
  # shellcheck disable=SC1090,SC1091
  source "$ROOT/install/stow.sh"

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

run_check "git diff whitespace" git diff --check
run_check "bash syntax" check_bash
run_check "zsh syntax" check_zsh
run_check "shfmt" check_shfmt
run_check "shellcheck" check_shellcheck
run_check "stow package list" check_stow_package_list
run_check "stow dry run to temporary home" check_stow_tmp_home

if [ "$failures" -gt 0 ]; then
  printf '\n%d validation check(s) failed.\n' "$failures" >&2
  exit 1
fi

printf '\nAll validation checks passed.\n'
