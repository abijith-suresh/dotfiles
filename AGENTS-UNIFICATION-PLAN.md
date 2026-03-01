# Agent Configuration Unification Plan

**Purpose:** Create a unified configuration system for multiple AI coding agents (OpenCode, Claude Code, Gemini CLI, Copilot CLI, GitHub CLI) with a single source of truth for skills, prompts, and shared configurations.

**Status:** 📝 Plan drafted - Awaiting review and approval

---

## Table of Contents

- [Overview](#overview)
- [Current Setup Analysis](#current-setup-analysis)
- [Proposed Structure](#proposed-structure)
- [Implementation Phases](#implementation-phases)
- [Symlink Strategy](#symlink-strategy)
- [File Structure Details](#file-structure-details)
- [Usage Workflow](#usage-workflow)
- [Benefits](#benefits)
- [Migration Checklist](#migration-checklist)

---

## Overview

### Problem Statement

Currently, AI coding agent configurations are scattered across multiple locations with partial overlapping:

- **Claude Code**: `~/.claude/` (skills, plugins, settings, runtime data)
- **Gemini CLI**: `~/.gemini/` (skills, settings, auth data)
- **Copilot CLI**: `~/.copilot/` (skills only)
- **OpenCode**: `~/.config/opencode/` (skills, package.json)
- **GitHub CLI**: `~/.config/gh/` (config.yml)
- **Shared Skills**: `~/.agents/skills/` (currently outside dotfiles)

Skills are partially unified via symlinks, but there's no central location for:
- Common prompts and instructions
- Shared templates
- Tool-specific settings tracking
- Version control of configurations

### Solution

Create a unified configuration system in `dotfiles/configs/agents/` with:
1. **Centralized skills repository** for all agents
2. **Shared prompts and templates** available to all tools
3. **Tool-specific config directories** for individual customization
4. **Stow-based management** for config files
5. **Automated symlinking** for cross-tool references

---

## Current Setup Analysis

### Existing Skills Symlinks (Already Working)

```
~/.agents/skills/              # Central skills directory (outside dotfiles)
├── frontend-design/
├── theme-factory/
├── agent-browser/
├── skill-creator/
├── web-design-guidelines/
└── find-skills/

# All tools currently symlink to ~/.agents/skills:
~/.claude/skills/            → ~/.agents/skills/
~/.gemini/skills/            → ~/.agents/skills/
~/.copilot/skills/           → ~/.agents/skills/
~/.config/agents/skills/     → ~/.agents/skills/
~/.config/opencode/skills/    → ~/.agents/skills/
```

### Individual Tool Config Locations

| Tool | Config Location | Files to Include | Files to Exclude |
|------|----------------|------------------|------------------|
| **Claude Code** | `~/.claude/` | `settings.json`, `plugins/`, `skills/` | `history.jsonl`, `cache/`, `downloads/`, `debug/`, `file-history/`, `session-env/`, `tasks/`, `todos/`, `backups/`, `shell-snapshots/`, `telemetry/`, `plans/`, `paste-cache/` |
| **Gemini CLI** | `~/.gemini/` | `settings.json`, `skills/` | `oauth_creds.json`, `tmp/`, `google_account_id`, `installation_id`, `user_id` |
| **Copilot CLI** | `~/.copilot/` | `skills/` | None (only skills) |
| **OpenCode** | `~/.config/opencode/` | `package.json`, `skills/` | None |
| **GitHub CLI** | `~/.config/gh/` | `config.yml`, `hosts.yml` | None |

### Current OpenCode Config

```json
{
  "dependencies": {
    "@opencode-ai/plugin": "1.2.15"
  }
}
```

### Current Claude Code Settings

```json
{
  "enabledPlugins": {
    "frontend-design@claude-plugins-official": true
  },
  "skipDangerousModePermissionPrompt": true
}
```

---

## Proposed Structure

### Directory Tree

```
dotfiles/
├── configs/
│   └── agents/                      # NEW: Unified AI agent configs
│       ├── shared/                   # Shared configs for all agents
│       │   ├── prompts/              # Common prompts/instructions
│       │   │   ├── coding-style.md
│       │   │   ├── security-guidelines.md
│       │   │   ├── project-structure.md
│       │   │   └── commit-style.md
│       │   ├── templates/            # Shared templates
│       │   │   ├── review-checklist.md
│       │   │   ├── pr-description.md
│       │   │   └── bug-report.md
│       │   └── skills/              # Central skills repository
│       │       ├── frontend-design/
│       │       ├── theme-factory/
│       │       ├── agent-browser/
│       │       ├── skill-creator/
│       │       ├── web-design-guidelines/
│       │       └── find-skills/
│       │
│       ├── claude/                   # Claude-specific configs
│       │   └── .config/
│       │       └── claude/
│       │           ├── skills/       # Symlink to ../../../shared/skills
│       │           └── settings.json
│       │
│       ├── gemini/                   # Gemini-specific configs
│       │   └── .gemini/
│       │       ├── skills/           # Symlink to ../../shared/skills
│       │       └── settings.json
│       │
│       ├── copilot/                  # Copilot-specific configs
│       │   └── .copilot/
│       │       └── skills/          # Symlink to ../../shared/skills
│       │
│       ├── opencode/                 # OpenCode-specific configs
│       │   └── .config/
│       │       └── opencode/
│       │           ├── skills/       # Symlink to ../../shared/skills
│       │           └── package.json
│       │
│       └── gh/                      # GitHub CLI configs
│           └── .config/
│               └── gh/
│                   └── config.yml
│
├── scripts/
│   └── setup-agents.sh             # NEW: Symlink creation script
│
├── README.md                        # Update with agent config docs
└── AGENTS.md                       # Update with agent-specific instructions
```

---

## Implementation Phases

### Phase 1: Create Directory Structure

```bash
cd ~/dotfiles/configs
mkdir -p agents/{shared/{prompts,templates,skills},claude/.config/claude,gemini/.gemini,copilot/.copilot,opencode/.config/opencode,gh/.config/gh}
```

**Tasks:**
1. Create `configs/agents/` with subdirectories for each tool
2. Create `configs/agents/shared/` with subdirectories for prompts, templates, skills
3. Move `~/.agents/skills/` → `configs/agents/shared/skills/`
   - This is the source of truth for all skills

### Phase 2: Move Configurations

#### 2.1 Claude Code

**Source:** `~/.claude/`
**Destination:** `configs/agents/claude/.config/claude/`

**Copy Commands:**
```bash
mkdir -p ~/dotfiles/configs/agents/claude/.config/claude

# Settings
cp ~/.claude/settings.json ~/dotfiles/configs/agents/claude/.config/claude/

# Plugins (selective)
cp -r ~/.claude/plugins ~/dotfiles/configs/agents/claude/.config/claude/

# Exclude (DO NOT COPY):
# - history.jsonl (session history)
# - cache/ (runtime cache)
# - downloads/ (downloaded files)
# - debug/ (debug logs)
# - file-history/ (file change history)
# - session-env/ (session environments)
# - tasks/ (task data)
# - todos/ (todo data)
# - backups/ (backup files)
# - shell-snapshots/ (shell snapshots)
# - telemetry/ (telemetry data)
# - plans/ (plan data)
# - paste-cache/ (paste cache)
```

#### 2.2 Gemini CLI

**Source:** `~/.gemini/`
**Destination:** `configs/agents/gemini/.gemini/`

**Copy Commands:**
```bash
mkdir -p ~/dotfiles/configs/agents/gemini/.gemini

# Settings
cp ~/.gemini/settings.json ~/dotfiles/configs/agents/gemini/.gemini/

# Exclude (DO NOT COPY):
# - oauth_creds.json (sensitive auth data)
# - tmp/ (temporary files)
# - google_account_id (account identifier)
# - installation_id (installation identifier)
# - user_id (user identifier)
```

#### 2.3 Copilot CLI

**Source:** `~/.copilot/`
**Destination:** `configs/agents/copilot/.copilot/`

**Copy Commands:**
```bash
mkdir -p ~/dotfiles/configs/agents/copilot/.copilot

# Only needs skills symlink (created in Phase 4)
# No other config files to copy
```

#### 2.4 OpenCode

**Source:** `~/.config/opencode/`
**Destination:** `configs/agents/opencode/.config/opencode/`

**Copy Commands:**
```bash
mkdir -p ~/dotfiles/configs/agents/opencode/.config/opencode

# Package config
cp ~/.config/opencode/package.json ~/dotfiles/configs/agents/opencode/.config/opencode/

# Copy any custom opencode config files if they exist
```

#### 2.5 GitHub CLI

**Source:** `~/.config/gh/`
**Destination:** `configs/agents/gh/.config/gh/`

**Copy Commands:**
```bash
mkdir -p ~/dotfiles/configs/agents/gh/.config/gh

# Config files
cp ~/.config/gh/config.yml ~/dotfiles/configs/agents/gh/.config/gh/
cp ~/.config/gh/hosts.yml ~/dotfiles/configs/agents/gh/.config/gh/
```

### Phase 3: Create Shared Resources

#### 3.1 Create Common Prompts

Create `configs/agents/shared/prompts/` with the following files:

**`coding-style.md`** - Coding standards and conventions
**`security-guidelines.md`** - Security best practices for AI agents
**`project-structure.md`** - Project organization guidelines
**`commit-style.md`** - Commit message conventions
**`review-checklist.md`** - Code review checklist

#### 3.2 Create Shared Templates

Create `configs/agents/shared/templates/` with the following files:

**`review-checklist.md`** - Code review checklist template
**`pr-description.md`** - Pull request description template
**`bug-report.md`** - Bug report template

### Phase 4: Symlink Strategy

#### Approach: Hybrid Stow + Setup Script

This approach uses Stow for config files and a setup script for cross-tool symlinks.

**Why this approach?**
- Stow handles individual tool configs cleanly
- Setup script creates the shared symlinks that Stow cannot handle
- Maintains separation of concerns
- Easy to understand and maintain

##### Step 4.1: Stow Config Directories

```bash
cd ~/dotfiles/configs/agents

# Stow shared configs (creates ~/.agents/skills/)
stow shared

# Stow each tool's config directory
stow claude      # Creates ~/.config/claude/
stow gemini      # Creates ~/.gemini/
stow copilot     # Creates ~/.copilot/
stow opencode    # Creates ~/.config/opencode/
stow gh          # Creates ~/.config/gh/
```

**What Stow Creates:**
- `~/.agents/skills/` → `dotfiles/configs/agents/shared/skills/`
- `~/.config/claude/settings.json` → `dotfiles/configs/agents/claude/.config/claude/settings.json`
- `~/.config/claude/plugins/` → `dotfiles/configs/agents/claude/.config/claude/plugins/`
- `~/.gemini/settings.json` → `dotfiles/configs/agents/gemini/.gemini/settings.json`
- `~/.copilot/` → `dotfiles/configs/agents/copilot/.copilot/`
- `~/.config/opencode/package.json` → `dotfiles/configs/agents/opencode/.config/opencode/package.json`
- `~/.config/gh/config.yml` → `dotfiles/configs/agents/gh/.config/gh/config.yml`

##### Step 4.2: Run Setup Script

```bash
cd ~/dotfiles
./scripts/setup-agents.sh
```

**What Setup Script Creates (Cross-Tool Symlinks):**
- `~/.claude/skills/` → `~/.agents/skills/`
- `~/.gemini/skills/` → `~/.agents/skills/`
- `~/.copilot/skills/` → `~/.agents/skills/`
- `~/.config/agents/skills/` → `~/.agents/skills/`
- `~/.config/opencode/skills/` → `~/.agents/skills/`

---

## Symlink Strategy

### Setup Script Implementation

**File:** `scripts/setup-agents.sh`

```bash
#!/usr/bin/env bash
# Setup script for creating cross-tool symlinks for AI agent configs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(dirname "$SCRIPT_DIR")"
SHARED_SKILLS="$DOTFILES_ROOT/configs/agents/shared/skills"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up AI agent configuration symlinks...${NC}"

# Check if shared skills directory exists
if [ ! -d "$SHARED_SKILLS" ]; then
    echo -e "${YELLOW}Error: Shared skills directory not found at $SHARED_SKILLS${NC}"
    echo "Please run 'stow shared' in configs/agents/ first"
    exit 1
fi

# Remove old symlinks if they exist
echo "Cleaning up old symlinks..."
rm -rf ~/.claude/skills 2>/dev/null || true
rm -rf ~/.gemini/skills 2>/dev/null || true
rm -rf ~/.copilot/skills 2>/dev/null || true
rm -rf ~/.config/agents/skills 2>/dev/null || true
rm -rf ~/.config/opencode/skills 2>/dev/null || true

# Create new symlinks
echo "Creating symlinks to shared skills..."

# Claude Code
ln -s ~/.agents/skills ~/.claude/skills
echo -e "${GREEN}✓${NC} Claude Code: ~/.claude/skills → ~/.agents/skills"

# Gemini CLI
ln -s ~/.agents/skills ~/.gemini/skills
echo -e "${GREEN}✓${NC} Gemini CLI: ~/.gemini/skills → ~/.agents/skills"

# Copilot CLI
ln -s ~/.agents/skills ~/.copilot/skills
echo -e "${GREEN}✓${NC} Copilot CLI: ~/.copilot/skills → ~/.agents/skills"

# Agents directory (OpenCode)
ln -s ~/.agents/skills ~/.config/agents/skills
echo -e "${GREEN}✓${NC} Agents: ~/.config/agents/skills → ~/.agents/skills"

# OpenCode
ln -s ~/.agents/skills ~/.config/opencode/skills
echo -e "${GREEN}✓${NC} OpenCode: ~/.config/opencode/skills → ~/.agents/skills"

echo -e "${GREEN}All symlinks created successfully!${NC}"
echo "Your AI agents will now use the centralized skills repository."
```

**Make executable:**
```bash
chmod +x scripts/setup-agents.sh
```

---

## File Structure Details

### Example: Shared Prompts

**`configs/agents/shared/prompts/coding-style.md`**
```markdown
# Coding Style Guidelines

## General Principles
- Write clear, self-documenting code
- Follow language-specific conventions
- Use meaningful variable and function names
- Keep functions focused and small (ideally < 50 lines)

## Language-Specific Rules

### JavaScript/TypeScript
- 2-space indentation
- No semicolons (use ESLint to enforce)
- Prefer `const` and `let` over `var`
- Use arrow functions for callbacks
- TypeScript: always specify return types for public APIs

### Python
- Follow PEP 8
- Use type hints for all function parameters and return values
- 4-space indentation
- Max line length: 88 characters (Black default)

### Rust
- Follow rustfmt conventions (use `cargo fmt`)
- Prefer `&str` over `&String` for function parameters
- Use `Option` and `Result` instead of `unwrap()`

## Commit Conventions
- Use imperative mood: "Add feature" not "Added feature"
- Keep first line under 72 characters
- Reference issues when applicable: "Fix authentication (closes #123)"
```

**`configs/agents/shared/prompts/security-guidelines.md`**
```markdown
# Security Guidelines for AI Agents

## Code Security
- Never hardcode credentials, API keys, or secrets
- Use environment variables for sensitive configuration
- Validate all user inputs
- Use parameterized queries to prevent SQL injection
- Sanitize data to prevent XSS attacks

## AI-Specific Security
- Don't suggest code that logs sensitive data
- Avoid suggesting weak cryptographic algorithms
- Don't expose internal system information in error messages
- Be cautious with eval(), exec(), and similar functions
- Never suggest disabling security features (e.g., `verify=False`)

## Best Practices
- Always use HTTPS for network requests
- Implement proper authentication and authorization
- Use the principle of least privilege
- Keep dependencies up to date
- Log security-relevant events
```

### Example: Tool-Specific Configs

**`configs/agents/claude/.config/claude/settings.json`**
```json
{
  "enabledPlugins": {
    "frontend-design@claude-plugins-official": true
  },
  "skipDangerousModePermissionPrompt": true,
  "sharedPromptsPath": "~/.config/agents/shared/prompts/"
}
```

**`configs/agents/gemini/.gemini/settings.json`**
```json
{
  "skillsPath": "~/.agents/skills",
  "sharedPromptsPath": "~/.config/agents/shared/prompts/"
}
```

**`configs/agents/opencode/.config/opencode/package.json`**
```json
{
  "dependencies": {
    "@opencode-ai/plugin": "1.2.15"
  },
  "skillsPath": "~/.agents/skills"
}
```

---

## Usage Workflow

### Initial Setup (One-Time)

```bash
# 1. Navigate to dotfiles
cd ~/dotfiles

# 2. Pull latest changes
git pull

# 3. Stow all agent configs
cd configs/agents
stow shared
stow claude
stow gemini
stow copilot
stow opencode
stow gh

# 4. Run setup script to create cross-tool symlinks
cd ../..
./scripts/setup-agents.sh

# 5. Verify setup
ls -la ~/.claude/skills
ls -la ~/.gemini/skills
ls -la ~/.copilot/skills
ls -la ~/.config/opencode/skills
```

### Daily/Regular Usage

**Update shared prompts:**
```bash
cd ~/dotfiles/configs/agents/shared/prompts
# Edit prompts as needed
git add .
git commit -m "Update shared coding prompts"
```

**Add a new skill:**
```bash
cd ~/dotfiles/configs/agents/shared/skills
mkdir new-skill
cd new-skill
# Create SKILL.md with skill definition
cd ~/dotfiles/configs/agents
stow shared --restow
git add .
git commit -m "Add new-skill for AI agents"
```

**Update Claude Code settings:**
```bash
cd ~/dotfiles/configs/agents/claude
# Edit settings.json
stow claude --restow
git add .
git commit -m "Update Claude Code settings"
```

**Re-sync all configs after pulling changes:**
```bash
cd ~/dotfiles
git pull
cd configs/agents
stow shared --restow
stow claude --restow
stow gemini --restow
stow copilot --restow
stow opencode --restow
stow gh --restow
cd ../..
./scripts/setup-agents.sh
```

### Troubleshooting

**Symlink broken:**
```bash
# Re-run setup script
cd ~/dotfiles
./scripts/setup-agents.sh
```

**Config not taking effect:**
```bash
# Re-stow the specific tool
cd ~/dotfiles/configs/agents
stow claude --restow  # or gemini, copilot, etc.
```

**Check what's symlinked:**
```bash
ls -la ~/.claude/skills
ls -la ~/.gemini/skills
ls -la ~/.copilot/skills
```

---

## Benefits

### 1. Single Source of Truth
- All skills in one location (`shared/skills/`)
- Changes propagate to all agents automatically
- No more duplicated or out-of-sync skills

### 2. Version Control
- Track changes to prompts, skills, and settings
- Roll back to previous versions if needed
- Collaborate on agent configurations

### 3. Easy Updates
- Stow handles config file management
- Setup script creates cross-tool symlinks
- Simple workflow for updates and additions

### 4. Tool-Specific Customization
- Each agent can have its own settings
- Plugin configs remain separate per tool
- Shared resources don't interfere with tool-specific needs

### 5. Shared Knowledge
- Common prompts available to all agents
- Templates for consistent outputs
- Coding standards and guidelines centralized

### 6. Clean Separation
- Runtime data excluded from version control
- Only what's needed for configuration is tracked
- Keeps repository size manageable

---

## Migration Checklist

### Pre-Migration

- [ ] Backup current configurations:
  ```bash
  cp -r ~/.claude ~/.claude.backup
  cp -r ~/.gemini ~/.gemini.backup
  cp -r ~/.copilot ~/.copilot.backup
  cp -r ~/.config/opencode ~/.config/opencode.backup
  cp -r ~/.config/gh ~/.config/gh.backup
  cp -r ~/.agents ~/.agents.backup
  ```

- [ ] Verify all tools are working with current setup
- [ ] List any custom plugins or configurations to preserve
- [ ] Document any tool-specific settings that shouldn't be shared

### Migration Steps

- [ ] Phase 1: Create directory structure
- [ ] Phase 2: Move configurations
  - [ ] Claude Code configs
  - [ ] Gemini CLI configs
  - [ ] Copilot CLI configs
  - [ ] OpenCode configs
  - [ ] GitHub CLI configs
- [ ] Phase 3: Create shared resources
  - [ ] Common prompts
  - [ ] Shared templates
- [ ] Phase 4: Setup symlinks
  - [ ] Run stow commands
  - [ ] Run setup script
  - [ ] Verify all symlinks

### Post-Migration Verification

- [ ] Test Claude Code with shared skills
- [ ] Test Gemini CLI with shared skills
- [ ] Test Copilot CLI with shared skills
- [ ] Test OpenCode with shared skills
- [ ] Verify shared prompts are accessible
- [ ] Check that all tools still work correctly
- [ ] Verify git status is clean (excluding runtime data)

### Cleanup

- [ ] Remove backup directories after successful migration
- [ ] Update this document with any lessons learned
- [ ] Update AGENTS.md with new workflow
- [ ] Update README.md with agent configuration section

---

## .gitignore Updates

Add the following to `.gitignore`:

```gitignore
# AI Agent Configs - Runtime Data (configs/agents/)
configs/agents/claude/.config/claude/history.jsonl
configs/agents/claude/.config/claude/cache/
configs/agents/claude/.config/claude/debug/
configs/agents/claude/.config/claude/downloads/
configs/agents/claude/.config/claude/file-history/
configs/agents/claude/.config/claude/session-env/
configs/agents/claude/.config/claude/tasks/
configs/agents/claude/.config/claude/todos/
configs/agents/claude/.config/claude/backups/
configs/agents/claude/.config/claude/shell-snapshots/
configs/agents/claude/.config/claude/telemetry/
configs/agents/claude/.config/claude/plans/
configs/agents/claude/.config/claude/paste-cache/

configs/agents/gemini/.gemini/oauth_creds.json
configs/agents/gemini/.gemini/tmp/
configs/agents/gemini/.gemini/google_account_id
configs/agents/gemini/.gemini/installation_id
configs/agents/gemini/.gemini/user_id

# Exclude all credential and sensitive files
**/*.credentials
**/*credentials.json
**/*oauth_creds.json
```

---

## Notes & Considerations

### Tool-Specific Behaviors

**Claude Code:**
- Heavily relies on plugins
- Maintains extensive runtime data
- Plugin marketplace in `~/.claude/plugins/marketplaces/`

**Gemini CLI:**
- Minimal configuration
- OAuth credentials should never be versioned
- May have additional auth tokens

**OpenCode:**
- Uses npm/package.json for plugin management
- Skills loaded from `~/.config/opencode/skills/`

**GitHub CLI:**
- Uses YAML for configuration
- Host-specific settings in `hosts.yml`

### Potential Issues

1. **Plugin Conflicts**: Some tools may have conflicting plugin structures
2. **Path Differences**: Tools may expect different paths for resources
3. **Version Incompatibility**: Skills may work differently across tool versions
4. **Symlink Maintenance**: Need to verify symlinks after system updates

### Future Enhancements

1. **Skill Versioning**: Tag skills with compatible tool versions
2. **Shared Tests**: Test skills across multiple tools
3. **Documentation Hub**: Central documentation for all skills
4. **Automated Backups**: Script to backup runtime data periodically
5. **Sync Script**: One-command sync across all machines

---

## References

- [GNU Stow Documentation](https://www.gnu.org/software/stow/)
- [Claude Code Documentation](https://code.claude.com/docs)
- [OpenCode Documentation](https://opencode.ai/docs)
- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)

---

**Last Updated:** 2026-02-26
**Status:** 📝 Plan drafted - Awaiting review and approval
