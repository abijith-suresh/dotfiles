#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d /tmp/dotfiles-pi-test.XXXXXX)"
test_home="$test_root/home"
fixture_bin="$test_root/bin"
log_dir="$test_root/log"
mkdir -p "$test_home/.local/bin" "$fixture_bin" "$log_dir"

cleanup() {
  if [ -d "$test_root" ]; then
    find "$test_root" -depth -delete
  fi
}
trap cleanup EXIT

cat >"$fixture_bin/mise" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$@" >"$TEST_LOG/mise-args"
EOF
chmod +x "$fixture_bin/mise"

cat >"$test_home/.local/bin/pi" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$test_home/.local/bin/pi"

PATH="$test_home/.local/bin:$fixture_bin:/usr/bin:/bin" \
  HOME="$test_home" \
  TEST_LOG="$log_dir" \
  DOTFILES_DIR="$REPO_DIR" \
  PLATFORM=ubuntu \
  PKG_MANAGER=apt \
  bash "$REPO_DIR/install/apps/agents/pi.sh"

[ "$(sed -n '1p' "$log_dir/mise-args")" = "exec" ]
[ "$(sed -n '2p' "$log_dir/mise-args")" = "node@lts" ]
[ "$(sed -n '3p' "$log_dir/mise-args")" = "--" ]
[ "$(sed -n '4p' "$log_dir/mise-args")" = "npm" ]
[ "$(sed -n '5p' "$log_dir/mise-args")" = "install" ]
[ "$(sed -n '6p' "$log_dir/mise-args")" = "-g" ]
[ "$(sed -n '7p' "$log_dir/mise-args")" = "--ignore-scripts" ]
[ "$(sed -n '8p' "$log_dir/mise-args")" = "--prefix" ]
[ "$(sed -n '9p' "$log_dir/mise-args")" = "$test_home/.local" ]
[ "$(sed -n '10p' "$log_dir/mise-args")" = "@earendil-works/pi-coding-agent" ]

printf '%s\n' 'Pi installer updates an existing installation with the official npm package.'
