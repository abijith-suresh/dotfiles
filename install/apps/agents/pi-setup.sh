#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Pi loads nearby package dependencies and aliases its SDK imports to the CLI.
# Link the same runtime packages for TypeScript instead of installing a second Pi.
# https://pi.dev/docs/latest/extensions
# https://pi.dev/docs/latest/sdk
# https://github.com/earendil-works/pi/blob/main/packages/coding-agent/src/core/extensions/loader.ts
PI_AGENT_DIR="$HOME/.pi/agent"
PI_RUNTIME_DIR="$HOME/.local/lib/node_modules/@earendil-works/pi-coding-agent"

if [ ! -f "$PI_AGENT_DIR/package-lock.json" ]; then
  info "no managed Pi package found"
  exit 0
fi

if [ ! -f "$PI_RUNTIME_DIR/package.json" ]; then
  die "Pi runtime missing; install Pi before its extension dependencies"
fi

info "pi setup dependencies"
mise exec node@lts -- npm ci --ignore-scripts --include=dev --prefix "$PI_AGENT_DIR"

# Resolve from the installed runtime, including dependencies nested by npm.
# npm ci removes these links each time, so repeated installs also resync SDK types.
PI_AGENT_DIR="$PI_AGENT_DIR" PI_RUNTIME_DIR="$PI_RUNTIME_DIR" \
  mise exec node@lts -- node --input-type=module <<'NODE'
import { createRequire } from 'node:module';
import { dirname, join } from 'node:path';
import { existsSync, lstatSync, mkdirSync, readFileSync, realpathSync, renameSync, symlinkSync } from 'node:fs';
const runtime = process.env.PI_RUNTIME_DIR;
const modules = join(process.env.PI_AGENT_DIR, 'node_modules');
const require = createRequire(join(runtime, 'package.json'));
for (const name of ['@earendil-works/pi-coding-agent', '@earendil-works/pi-ai', '@earendil-works/pi-agent-core', '@earendil-works/pi-tui', 'typebox']) {
  let source = name === '@earendil-works/pi-coding-agent' ? runtime : require.resolve.paths(name).map(path => join(path, name)).find(path => existsSync(join(path, "package.json")));
  if (!source) throw new Error(`Cannot locate installed ${name}`);
  while (!existsSync(join(source, 'package.json')) || JSON.parse(readFileSync(join(source, 'package.json'), 'utf8')).name !== name) {
    const parent = dirname(source);
    if (parent === source) throw new Error(`Cannot locate installed ${name}`);
    source = parent;
  }
  const target = join(modules, name);
  mkdirSync(dirname(target), { recursive: true });
  symlinkSync(source, target, 'dir');
}
// Pi's jiti loader canonicalizes stowed source files. Let those imports reach
// the same HOME dependencies through ignored local state in the source tree.
const sourceRoot = dirname(realpathSync(join(process.env.PI_AGENT_DIR, 'package.json')));
const sourceModules = join(sourceRoot, 'node_modules');
function backupDependencies(directory) {
  if (!lstatSync(directory, { throwIfNoEntry: false })) return;
  let backup = `${directory}.backup`;
  for (let suffix = 1; lstatSync(backup, { throwIfNoEntry: false }); suffix++)
    backup = `${directory}.backup.${suffix}`;
  renameSync(directory, backup);
  console.log(`Backed up Pi dependencies to ${backup}`);
}
if (sourceModules !== modules) {
  const previous = lstatSync(sourceModules, { throwIfNoEntry: false });
  let pointsToHome = false;
  if (previous?.isSymbolicLink()) {
    try { pointsToHome = realpathSync(sourceModules) === realpathSync(modules); } catch {}
  }
  if (previous && !pointsToHome) backupDependencies(sourceModules);
  if (!pointsToHome) symlinkSync(modules, sourceModules, 'dir');
}
// The removed subagents package had its own dependency install. It must not
// shadow the shared package, whether reached through HOME or canonical sources.
for (const root of new Set([sourceRoot, process.env.PI_AGENT_DIR]))
  backupDependencies(join(root, 'extensions/subagents/node_modules'));
NODE

mise exec node@lts -- npm run check --prefix "$PI_AGENT_DIR"
