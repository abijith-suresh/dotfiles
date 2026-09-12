#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d /tmp/dotfiles-antigravity-test.XXXXXX)"
test_home="$test_root/home"
fixture_bin="$test_root/bin"
log_dir="$test_root/log"
mkdir -p "$test_home" "$fixture_bin" "$log_dir"

cleanup() {
  if [ -d "$test_root" ]; then
    find "$test_root" -depth -delete
  fi
}
trap cleanup EXIT

cat >"$fixture_bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

[ "$#" -eq 2 ]
[ "$1" = "-fsSL" ]
[ "$2" = "https://antigravity.google/cli/install.sh" ]
printf '%s\n' "$@" >"$TEST_LOG/curl-args"
cat <<'INSTALLER'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$@" >"$TEST_LOG/installer-args"
mkdir -p "$HOME/.local/bin"
cat >"$HOME/.local/bin/agy" <<'AGY'
#!/usr/bin/env bash
printf '%s\n' 'fixture agy'
AGY
chmod +x "$HOME/.local/bin/agy"
INSTALLER
EOF
chmod +x "$fixture_bin/curl"

PATH="$fixture_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  TEST_LOG="$log_dir" \
  DOTFILES_DIR="$REPO_DIR" \
  PLATFORM=ubuntu \
  PKG_MANAGER=apt \
  bash "$REPO_DIR/install/apps/agents/antigravity.sh"

[ -x "$test_home/.local/bin/agy" ]
[ "$("$test_home/.local/bin/agy")" = "fixture agy" ]
[ "$(sed -n '1p' "$log_dir/curl-args")" = "-fsSL" ]
[ "$(sed -n '2p' "$log_dir/curl-args")" = "https://antigravity.google/cli/install.sh" ]
[ "$(sed -n '1p' "$log_dir/installer-args")" = "--skip-aliases" ]
[ "$(sed -n '2p' "$log_dir/installer-args")" = "--skip-path" ]

mv "$fixture_bin/curl" "$fixture_bin/curl-first"
cat >"$fixture_bin/curl" <<'EOF'
#!/usr/bin/env bash
exit 99
EOF
chmod +x "$fixture_bin/curl"

PATH="$test_home/.local/bin:$fixture_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  TEST_LOG="$log_dir" \
  DOTFILES_DIR="$REPO_DIR" \
  PLATFORM=ubuntu \
  PKG_MANAGER=apt \
  bash "$REPO_DIR/install/apps/agents/antigravity.sh" >/dev/null

printf '%s\n' 'Antigravity installation and repeatability passed.'
