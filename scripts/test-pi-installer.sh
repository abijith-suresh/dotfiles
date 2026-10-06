#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d /tmp/dotfiles-pi-test.XXXXXX)"
test_home="$test_root/home"
fixture_bin="$test_root/bin"
log_dir="$test_root/log"
mkdir -p "$test_home/.local/bin" "$fixture_bin" "$log_dir"
trap 'find "$test_root" -depth -delete' EXIT

cat >"$fixture_bin/mise" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [ "$4" = npm ]; then
  printf '%s\n' "$@" >"$TEST_LOG/mise-args"
else
  shift 3
  exec "$@"
fi
EOF
cat >"$test_home/.local/bin/pi" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$TEST_LOG/pi-args"
EOF
chmod +x "$fixture_bin/mise" "$test_home/.local/bin/pi"

export PATH="$test_home/.local/bin:$fixture_bin:$PATH"
export HOME="$test_home" TEST_LOG="$log_dir" DOTFILES_DIR="$REPO_DIR"
export PLATFORM=ubuntu PKG_MANAGER=apt
# Keep these checks isolated even when the caller uses a custom Pi directory.
export PI_AGENT_DIR="$test_home/.pi/agent"

bash "$REPO_DIR/install/apps/agents/pi.sh"
expected=(exec node@lts -- npm install -g --ignore-scripts --prefix "$test_home/.local" @earendil-works/pi-coding-agent@latest)
mapfile -t actual <"$log_dir/mise-args"
diff -u <(printf '%s\n' "${expected[@]}") <(printf '%s\n' "${actual[@]}")
bash "$REPO_DIR/install/apps/agents/tangent.sh"
tangent_source="$(node -p 'require(process.argv[1]).packages[0]' "$REPO_DIR/configs/pi/.pi/agent/settings.json")"
diff -u <(printf '%s\n' install "$tangent_source") "$log_dir/pi-args"
printf '%s\n' 'Pi updates through npm; Tangent installs the tracked release through Pi.'

# Optional native integration test. No dependency installation in this repo.
if [ -n "${PI_TEST_RUNTIME:-}" ]; then
  export PI_TEST_RUNTIME
  cat >"$test_home/.local/bin/pi" <<'EOF'
#!/usr/bin/env bash
exec node "$PI_TEST_RUNTIME/dist/cli.js" "$@"
EOF
  fixture_repo="$test_root/repo"
  mkdir -p "$fixture_repo/configs"
  cp -R "$REPO_DIR/configs/pi" "$fixture_repo/configs/"
  cp "$REPO_DIR/configs/.stowrc" "$fixture_repo/configs/"
  export DOTFILES_DIR="$fixture_repo"
  # The helper sources the real installer library, but reads fixture settings.
  mkdir -p "$fixture_repo/install"
  cp "$REPO_DIR/install/lib.sh" "$fixture_repo/install/"
  stow --dir "$fixture_repo/configs" --target "$HOME" --no-folding pi
  bash "$REPO_DIR/install/apps/agents/tangent.sh"
  cp "$HOME/.pi/agent/settings.json" "$test_root/fresh-settings"
  bash "$REPO_DIR/install/apps/agents/tangent.sh"
  cmp "$test_root/fresh-settings" "$HOME/.pi/agent/settings.json"

  node --input-type=module <<'NODE'
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
const sdk = await import(pathToFileURL(`${process.env.PI_TEST_RUNTIME}/dist/index.js`).href);
const agentDir = process.env.PI_AGENT_DIR;
const settings = JSON.parse(readFileSync(`${agentDir}/settings.json`, 'utf8'));
assert.equal(settings.theme, 'catppuccin-mocha');
const settingsManager = sdk.SettingsManager.create(process.env.HOME, agentDir, { projectTrusted: false });
const loader = new sdk.DefaultResourceLoader({ cwd: process.env.HOME, agentDir, settingsManager });
await loader.reload();
assert.deepEqual(loader.getExtensions().errors, []);
assert.deepEqual(loader.getThemes().diagnostics, []);
assert(loader.getThemes().themes.some(theme => theme.name === settings.theme));
const tools = loader.getExtensions().extensions.flatMap(extension => [...extension.tools.keys()]);
assert(!tools.some(name => name === 'ask_user' || name.startsWith('subagent_')));
console.log('Fresh Stow settings discover Tangent Mocha through the native package loader.');
NODE

  # Replace the settings symlink as a CLI can, then preserve user settings and
  # package resource filters while Pi updates the existing Tangent declaration.
  unlink "$HOME/.pi/agent/settings.json"
  mkdir -p "$HOME/.pi/agent/sessions" "$test_root/other-package"
  printf '%s\n' '{"name":"fixture-package","pi":{"extensions":[]}}' >"$test_root/other-package/package.json"
  printf '%s\n' '{"fixture":"auth"}' >"$HOME/.pi/agent/auth.json"
  printf '%s\n' 'session fixture' >"$HOME/.pi/agent/sessions/fixture.jsonl"
  node --input-type=module <<'NODE'
import { writeFileSync } from 'node:fs';
const settings = {
  theme: 'dark', defaultProvider: 'fixture-provider', defaultModel: 'fixture-model',
  compaction: { enabled: false }, unknownSetting: { preserved: true },
  packages: [process.env.HOME + '/../other-package']
};
writeFileSync(`${process.env.PI_AGENT_DIR}/settings.json`, JSON.stringify(settings, null, 2) + '\n');
NODE
  cp "$HOME/.pi/agent/settings.json" "$test_root/owned-settings"
  stow --dir "$fixture_repo/configs" --target "$HOME" --no-folding --ignore=settings.json pi
  bash "$REPO_DIR/install/apps/agents/tangent.sh"
  export TEST_ROOT="$test_root" TANGENT_SOURCE="$tangent_source"
  node --input-type=module <<'NODE'
import assert from 'node:assert/strict';
import { readFileSync, writeFileSync } from 'node:fs';
const read = path => JSON.parse(readFileSync(path, 'utf8'));
const before = read(`${process.env.TEST_ROOT}/owned-settings`);
const after = read(`${process.env.PI_AGENT_DIR}/settings.json`);
before.packages.push(process.env.TANGENT_SOURCE);
assert.deepEqual(after, before);
// Updating an existing declaration also retains its resource filters.
after.packages[1] = { source: 'git:github.com/abijith-suresh/tangent@main', themes: [], extensions: [] };
writeFileSync(`${process.env.PI_AGENT_DIR}/settings.json`, JSON.stringify(after, null, 2) + '\n');
writeFileSync(`${process.env.TEST_ROOT}/filtered-settings`, JSON.stringify(after));
NODE
  bash "$REPO_DIR/install/apps/agents/tangent.sh"
  node --input-type=module <<'NODE'
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
const read = path => JSON.parse(readFileSync(path, 'utf8'));
const before = read(`${process.env.TEST_ROOT}/filtered-settings`);
before.packages[1].source = process.env.TANGENT_SOURCE;
assert.deepEqual(read(`${process.env.PI_AGENT_DIR}/settings.json`), before);
NODE
  cp "$HOME/.pi/agent/settings.json" "$test_root/registered-settings"
  bash "$REPO_DIR/install/apps/agents/tangent.sh"
  cmp "$test_root/registered-settings" "$HOME/.pi/agent/settings.json"
  grep -qx '{"fixture":"auth"}' "$HOME/.pi/agent/auth.json"
  grep -qx 'session fixture' "$HOME/.pi/agent/sessions/fixture.jsonl"
  printf '%s\n' 'Existing theme, settings, package filters, auth, and sessions survive repeat installation.'
fi
