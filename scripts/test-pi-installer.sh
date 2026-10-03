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
[ "$(sed -n '10p' "$log_dir/mise-args")" = "@earendil-works/pi-coding-agent@latest" ]

printf '%s\n' 'Pi installer updates an existing installation with the official npm package.'

# Setup must fail clearly before invoking npm when the runtime is missing.
mkdir -p "$test_home/.pi/agent"
cp "$REPO_DIR/configs/pi/.pi/agent/package.json" "$test_home/.pi/agent/"
cp "$REPO_DIR/configs/pi/.pi/agent/package-lock.json" "$test_home/.pi/agent/"
if output="$(PATH="$fixture_bin:/usr/bin:/bin" HOME="$test_home" DOTFILES_DIR="$REPO_DIR" \
  PLATFORM=ubuntu PKG_MANAGER=apt bash "$REPO_DIR/install/apps/agents/pi-setup.sh" 2>&1)"; then
  printf '%s\n' 'Setup unexpectedly accepted a missing runtime.' >&2
  exit 1
fi
[[ "$output" == *'Pi runtime missing'* ]]
[[ "$output" != *'command not found'* ]]
printf '%s\n' 'Pi setup reports a missing runtime without invoking an undefined helper.'

# Use an already isolated CLI installation for the full Stow/SDK check.
# This optional check installs only locked extension dependencies, never models.
if [ -n "${PI_TEST_RUNTIME:-}" ]; then
  fixture_repo="$test_root/repo"
  mkdir -p "$fixture_repo/configs" "$fixture_repo/install" "$test_root/cache"
  tar --exclude=node_modules -C "$REPO_DIR/configs" -cf - pi | tar -C "$fixture_repo/configs" -xf -
  cp "$REPO_DIR/configs/.stowrc" "$fixture_repo/configs/"
  cp "$REPO_DIR/install/lib.sh" "$fixture_repo/install/"
  rm -rf "$test_home/.pi"
  stow --dir "$fixture_repo/configs" --target "$test_home" --no-folding pi
  mkdir -p "$test_home/.local/lib/node_modules/@earendil-works"
  ln -s "$PI_TEST_RUNTIME" "$test_home/.local/lib/node_modules/@earendil-works/pi-coding-agent"
  cat >"$fixture_bin/mise" <<'MISE'
#!/usr/bin/env bash
set -euo pipefail
[ "$1" = exec ] && [ "$2" = node@lts ] && [ "$3" = -- ]
shift 3
exec "$@"
MISE
  chmod +x "$fixture_bin/mise"
  export HOME="$test_home" XDG_CACHE_HOME="$test_root/cache" npm_config_cache="$test_root/cache/npm"
  export DOTFILES_DIR="$fixture_repo" PLATFORM=ubuntu PKG_MANAGER=apt
  export PATH="$fixture_bin:$PATH"
  source_modules="$fixture_repo/configs/pi/.pi/agent/node_modules"
  mkdir "$source_modules"
  printf '%s\n' 'old dependency content' >"$source_modules/retained.txt"
  legacy_source_modules="$fixture_repo/configs/pi/.pi/agent/extensions/subagents/node_modules"
  legacy_home_modules="$test_home/.pi/agent/extensions/subagents/node_modules"
  mkdir "$legacy_source_modules" "$legacy_home_modules"
  printf '%s\n' 'old nested source' >"$legacy_source_modules/retained.txt"
  printf '%s\n' 'old nested home' >"$legacy_home_modules/retained.txt"
  lock_before="$(sha256sum "$fixture_repo/configs/pi/.pi/agent/package-lock.json")"
  bash "$REPO_DIR/install/apps/agents/pi-setup.sh"
  [ "$(cat "$source_modules.backup/retained.txt")" = 'old dependency content' ]
  [ "$(cat "$legacy_source_modules.backup/retained.txt")" = 'old nested source' ]
  [ "$(cat "$legacy_home_modules.backup/retained.txt")" = 'old nested home' ]
  [ ! -e "$legacy_source_modules" ]
  [ ! -e "$legacy_home_modules" ]
  # Idempotent setup leaves the current HOME link and first backup intact.
  bash "$REPO_DIR/install/apps/agents/pi-setup.sh"
  [ ! -e "$source_modules.backup.1" ]
  mkdir "$test_root/foreign-deps"
  printf '%s\n' 'foreign content' >"$test_root/foreign-deps/retained.txt"
  rm "$source_modules"
  ln -s "$test_root/foreign-deps" "$source_modules"
  bash "$REPO_DIR/install/apps/agents/pi-setup.sh"
  [ -L "$source_modules.backup.1" ]
  [ "$(cat "$source_modules.backup.1/retained.txt")" = 'foreign content' ]
  rm "$source_modules"
  ln -s "$test_root/missing-deps" "$source_modules"
  bash "$REPO_DIR/install/apps/agents/pi-setup.sh"
  [ -L "$source_modules.backup.2" ]
  [ "$(readlink "$source_modules.backup.2")" = "$test_root/missing-deps" ]
  [ "$(cat "$source_modules.backup/retained.txt")" = 'old dependency content' ]
  [ "$lock_before" = "$(sha256sum "$fixture_repo/configs/pi/.pi/agent/package-lock.json")" ]
  [ -L "$test_home/.pi/agent/package.json" ]
  [ -L "$fixture_repo/configs/pi/.pi/agent/node_modules" ]
  [ "$(readlink -f "$fixture_repo/configs/pi/.pi/agent/node_modules")" = "$test_home/.pi/agent/node_modules" ]
  [ "$(readlink -f "$test_home/.pi/agent/node_modules/@earendil-works/pi-coding-agent")" = "$(readlink -f "$PI_TEST_RUNTIME")" ]
  mise exec node@lts -- npm test --prefix "$test_home/.pi/agent"
  PI_AGENT_DIR="$test_home/.pi/agent" mise exec node@lts -- node --input-type=module <<'NODE'
import assert from 'node:assert/strict';
import { pathToFileURL } from 'node:url';
const sdk = await import(pathToFileURL(`${process.env.PI_TEST_RUNTIME}/dist/index.js`).href);
const agentDir = process.env.PI_AGENT_DIR;
const cwd = process.env.HOME;
const settingsManager = sdk.SettingsManager.create(cwd, agentDir, { projectTrusted: false });
const loader = new sdk.DefaultResourceLoader({ cwd, agentDir, settingsManager });
await loader.reload();
const loaded = loader.getExtensions();
assert.deepEqual(loaded.errors, []);
const tools = loaded.extensions.flatMap(extension => [...extension.tools.keys()]);
for (const name of ['ask_user', 'subagent_spawn', 'subagent_wait', 'subagent_cancel', 'subagent_check', 'subagent_list']) assert(tools.includes(name));
const commands = loaded.extensions.flatMap(extension => [...extension.commands.keys()]);
assert(commands.includes('clarify'));
assert(!commands.includes('subagents'));
console.log('Stowed extensions load through the installed Pi SDK, with clarify preserved.');
NODE
  printf '%s\n' 'Repeated Pi setup preserves the lock and resolves dependencies in a real Stow layout.'
fi
