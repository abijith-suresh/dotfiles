# AGENTS.md - Dotfiles Repository Guide

This guide is for agentic coding assistants working in this personal dotfiles repository. It covers installation scripts, code style conventions, and repository structure.

## Repository Overview

This is a personal dotfiles repository managed with GNU Stow for Unix-like systems (Linux/macOS) and PowerShell scripts for Windows. It contains configuration files for shell environments, editors, terminal tools, and development utilities.

**Primary Purpose**: Manage and version control personal configuration files across multiple machines and operating systems.

## Directory Structure

```
dotfiles/
├── configs/          # All configuration files organized by application (for GNU Stow)
│   ├── bash/        # Bash shell configuration
│   ├── bat/         # bat (cat replacement) config
│   ├── git/         # Git configuration
│   ├── nvim/        # Neovim editor config (Lua-based)
│   ├── powershell/  # PowerShell profile
│   ├── starship/    # Starship prompt config
│   └── zsh/         # Zsh shell configuration
├── install/         # OS-specific install scripts
│   ├── wsl.sh      # Ubuntu WSL package installer
│   └── windows.ps1 # Windows package manager (winget) script
├── scripts/         # Utility scripts
│   └── update.sh   # System and plugin updater
└── wallpapers/      # Visual assets
```

## Installation & Setup Commands

### Deploy Configurations (GNU Stow)
```bash
cd dotfiles/configs
stow <package_name>  # e.g., stow zsh bash git starship nvim tmux

# Deploy all configs
stow */

# Remove a config
stow -D <package_name>
```

### Install System Packages

**Ubuntu/WSL:**
```bash
./install/wsl.sh
```
Installs: bat, btop, eza, fastfetch, fzf, git, htop, neovim, ripgrep, tmux, tree, zoxide, zsh

**Windows:**
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\install\windows.ps1
```
Installs via winget: Chrome, Discord, Docker, Git, Neovim, VSCode, Obsidian, Starship, and more.

### Update System & Configs
```bash
./scripts/update.sh
```
Updates APT packages, Zinit plugins, and performs system maintenance.

## Code Style Guidelines

### Shell Scripts (Bash/Zsh)

**File Headers:**
- Include shebang: `#!/bin/bash` or `#!/usr/bin/env bash`
- Add brief description in comments
- Use `set -e` for error handling in critical scripts

**Formatting:**
- 2 spaces for indentation (NOT tabs)
- Use lowercase for variable names: `packages=()`, `app_name="value"`
- Quote all variables: `"$variable"` not `$variable`
- Use arrays for lists: `packages=(bat btop eza)`

**Functions:**
```bash
# Function description
function_name() {
  local variable="value"
  command "$variable"
}
```

**Error Handling:**
- Use `|| { echo "Error message"; continue; }` for non-critical failures
- Use `set -e` at start for critical scripts
- Provide informative error messages

**Comments:**
- Use `# ---` for section headers
- Comment non-obvious logic
- Keep inline comments concise

### Lua (Neovim Config)

**File Organization:**
- Core settings: `lua/core/` (options.lua, keymaps.lua)
- Plugins: `lua/plugins/` (one file per plugin/feature)
- LSP config: `lua/plugins/lsp/`

**Formatting:**
- 2 spaces for indentation (NOT tabs)
- Use double quotes for strings: `"string"`
- Comment structure:
  ```lua
  -- Section description
  local variable = value -- inline comment
  ```

**Module Structure:**
```lua
-- File: lua/plugins/example.lua
return {
  "author/plugin-name",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {},
  config = function()
    -- Plugin configuration
  end,
}
```

**Settings:**
- Use `vim.opt` for options: `vim.opt.tabstop = 2`
- Use `vim.keymap` for keymaps
- Group related settings with comments

### PowerShell Scripts

**Formatting:**
- Use PascalCase for function names: `Update-Environment`
- Use proper capitalization: `$ErrorActionPreference`
- 4 spaces for indentation in functions
- Section headers: `# --------------------------------------`

**Error Handling:**
- Set `$ErrorActionPreference = "Stop"` for critical scripts
- Use try-catch blocks with informative messages
- Use `-ErrorAction SilentlyContinue` for optional imports

**Functions:**
```powershell
function Function-Name {
    param([string]$parameter)
    # Function body
}
```

## Git Configuration Standards

**Default Branch:** `main`

**Commit Style:**
- Use imperative mood: "Add feature" not "Added feature"
- Keep first line under 72 characters
- Reference issues when applicable

**Git Workflow:**
- Auto-setup remote on push: enabled
- Rebase on pull: enabled
- Auto-stash during rebase: enabled
- Follow tags on push: enabled

## Common Aliases

### Shell (Bash/Zsh)
```bash
ls → eza --color=auto
cat → bat
cd → z (zoxide)
v → nvim
gs → git status
gc → git commit -m
```

### Git Shortcuts
```bash
gs  = git status
ga  = git add
gc  = git commit -m
gp  = git push
gl  = git pull / git log (context-dependent)
gco = git checkout
gb  = git branch
```

## Testing & Validation

**No formal test suite**, but validation methods:

1. **Shell Scripts:** Run with `bash -n script.sh` to check syntax
2. **Stow Deployment:** Use `stow -n <package>` for dry-run
3. **Manual Testing:** Deploy configs in a test environment before production use

## Important Notes for Agents

1. **Never modify user-specific data** in .gitconfig (name, email)
2. **Preserve exact indentation** when editing config files
3. **Test scripts in WSL/Ubuntu environment** - primary target platform
4. **Don't break existing aliases** - users rely on muscle memory
5. **Maintain GNU Stow compatibility** - proper directory structure in configs/
6. **Check dependencies** before adding new tools to install scripts
7. **Keep shell startup fast** - avoid expensive operations in .bashrc/.zshrc
8. **Document breaking changes** clearly in commit messages

## Editor Configuration (Neovim)

- Plugin manager: **lazy.nvim**
- Indentation: **2 spaces**, expand tabs
- Line numbers: relative + absolute on cursor line
- LSP servers: lua_ls, tsserver, html, cssls, tailwindcss, emmet_ls, pyright
- Use system clipboard by default
- No swap files

## Platform-Specific Notes

**WSL (Primary Target):**
- Ubuntu-based
- Uses Zinit for Zsh plugin management
- Starship prompt for both Bash and Zsh
- Integration with Windows filesystem expected

**Windows:**
- PowerShell profile with posh-git
- winget for package management
- Git Bash compatibility maintained

## File Encoding & Line Endings

- **Unix files**: LF line endings
- **Windows files**: CRLF acceptable for .ps1 files
- **Encoding**: UTF-8 without BOM preferred

---

**Last Updated**: 2026-01-17
**Maintained by**: Abijith Suresh
**Repository**: Personal dotfiles configuration
