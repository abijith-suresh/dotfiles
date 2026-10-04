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

expected=(exec node@lts -- npm install -g --ignore-scripts --prefix "$test_home/.local" @earendil-works/pi-coding-agent@latest)
mapfile -t actual <"$log_dir/mise-args"
diff -u <(printf '%s\n' "${expected[@]}") <(printf '%s\n' "${actual[@]}")

printf '%s\n' 'Pi installer updates an existing installation with the official npm package.'

# An installed SDK can verify discovery in a real Stow layout without any
# extension package manifest, node_modules, compilation, or setup step.
if [ -n "${PI_TEST_RUNTIME:-}" ]; then
  fixture_repo="$test_root/repo"
  mkdir -p "$fixture_repo/configs"
  cp -R "$REPO_DIR/configs/pi" "$fixture_repo/configs/"
  cp "$REPO_DIR/configs/.stowrc" "$fixture_repo/configs/"
  stow --dir "$fixture_repo/configs" --target "$test_home" --no-folding pi
  HOME="$test_home" PI_AGENT_DIR="$test_home/.pi/agent" node --input-type=module <<'NODE'
import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
for (const key of Object.keys(process.env)) {
  if (!['HOME', 'PATH', 'PI_AGENT_DIR', 'PI_TEST_RUNTIME'].includes(key)) delete process.env[key];
}
const sdk = await import(pathToFileURL(`${process.env.PI_TEST_RUNTIME}/dist/index.js`).href);
const agentDir = process.env.PI_AGENT_DIR;
const cwd = process.env.HOME;
assert(!existsSync(`${agentDir}/node_modules`));
assert(!existsSync(`${agentDir}/package.json`));
assert(!existsSync(`${agentDir}/tests`));
const settingsManager = sdk.SettingsManager.create(cwd, agentDir, { projectTrusted: false });
const loader = new sdk.DefaultResourceLoader({ cwd, agentDir, settingsManager });
await loader.reload();
const loaded = loader.getExtensions();
assert.deepEqual(loaded.errors, []);
const tools = loaded.extensions.flatMap(extension => [...extension.tools.keys()]);
for (const name of ['ask_user', 'subagent_spawn', 'subagent_wait', 'subagent_cancel', 'subagent_check', 'subagent_list']) assert(tools.includes(name));
const commands = loaded.extensions.flatMap(extension => [...extension.commands.keys()]);
assert(commands.includes('clarify'));
assert(commands.includes('btw'));
assert(loader.getSkills().skills.some(skill => skill.name === 'subagents'));
assert(loader.getThemes().themes.some(theme => theme.name === 'catppuccin-mocha'));
const { session, modelFallbackMessage } = await sdk.createAgentSession({ cwd, agentDir, settingsManager, resourceLoader: loader });
try {
  assert.match(modelFallbackMessage, /No models available/);
  await session.bindExtensions({ mode: 'print' });
  const tool = session.getToolDefinition('subagent_spawn');
  const result = await tool.execute('offline-test', { name: 'offline', prompt: 'Return a short answer', mode: 'foreground' }, undefined, undefined, session.extensionRunner.createContext());
  assert.equal(result.details.results[0].status, 'error');
  assert.match(result.content[0].text, /No API key found/);
  console.log('Stowed extensions, skills, and theme load directly; a native foreground child returns an offline preflight error.');
} finally {
  await session.extensionRunner.emit({ type: 'session_shutdown', reason: 'quit' });
  session.dispose();
}
NODE
fi
