# PLAN.md

## Goal

Modernize the dotfiles repo by adopting sensible defaults from basecamp/omakub — adding a multi-tool theme system, modular install scripts with interactive UI, new tool configs (zellij, fastfetch, btop), switching to mise for language version management, and trimming aliases to a minimal set — while preserving the existing GNU Stow structure and XDG conventions.

## Approach

- **Copy omakub patterns, not omakub itself** — adopt the modular install loop, gum-based menus, per-theme folder structure, and per-tool installer pattern, but adapted to our Stow-based layout and zsh-first shell.
- **Add, don't replace blindly** — keep tmux, keep zsh, keep starship. Add zellij as an alternative. Add configs that are missing (fastfetch, btop, zellij). Layer mise on top, then phase out NVM/SDKMAN from shell config.
- **Theme system** — port 10 themes from omakub with WSL-relevant files only (zellij.kdl, btop.theme, neovim.lua, starship.toml, fzf colors, bat theme). A `dotfiles theme` command switches all tools at once.
- **Modular install** — restructure install/ into per-tool scripts sourced in a loop, with OS-aware routing (terminal/ for all platforms, desktop/ for GNOME only).
- **Nice UI** — use gum for interactive menus, ASCII art header, a `dotfiles` CLI command for theme switching and updates.

## Steps

### Phase 1: New Config Files (no breaking changes)

1. **Create `configs/zellij/` stow package**
   - `configs/zellij/.config/zellij/config.kdl` — omakub's keybindings (locked-mode, vim-style)
   - Port catppuccin theme inline for now (theme system in Phase 3 will replace this)

2. **Create `configs/fastfetch/` stow package**
   - `configs/fastfetch/.config/fastfetch/config.jsonc` — omakub's structured hardware/software/uptime display
   - Remove WSL-irrelevant modules (DE, WM, WM theme, icons, cursor, terminal font)

3. **Create `configs/btop/` stow package**
   - `configs/btop/.config/btop/btop.conf` — omakub's pre-configured btop with sensible defaults
   - Theme will be set by theme system in Phase 3

### Phase 2: Shell Config Updates

4. **Update `.zsh_aliases`** — replace with the agreed minimal set:
   ```
   # File Listing (eza)
   ls, ll, la, lt (with --long --git on lt)

   # Replacements
   cat→bat, mkdir→mkdir -pv, cd→z, grep→color

   # Navigation
   .., ..., ....

   # Shortcuts
   c=clear, please=sudo, :q=exit

   # Git (faster than lazygit inline)
   g=git, gcm, gcam, gcad, gp, gl

   # Tools
   lzg=lazygit, lzd=lazydocker

   # n function (nvim . or nvim <file>)
   ```

5. **Update `.zsh_functions`** — add from omakub:
   - `compress()` — tar.gz a directory
   - `decompress` — extract tar.gz
   - `webm2mp4()` — convert screen recordings

6. **Update `.zshrc`** — phase out NVM/SDKMAN, add mise:
   - Remove NVM block (`NVM_DIR`, `nvm.sh`, `bash_completion`)
   - Remove SDKMAN block (`SDKMAN_DIR`, `sdkman-init.sh`)
   - Remove Bun block (mise handles Node/Bun)
   - Add `eval "$(mise activate zsh)"` after zinit plugins
   - Keep zoxide, starship, fzf, opencode PATH as-is

7. **Update `.bashrc`** — same changes as .zshrc for bash parity:
   - Remove NVM block
   - Add `eval "$(mise activate bash)"`
   - Update aliases to match new minimal set

### Phase 3: Theme System

8. **Create `themes/` directory** with 10 themes ported from omakub:
   ```
   themes/
   ├── catppuccin/
   │   ├── zellij.kdl
   │   ├── btop.theme
   │   ├── neovim.lua
   │   ├── alacritty.toml
   │   └── starship.toml      (our own)
   ├── tokyo-night/
   ├── nord/
   ├── gruvbox/
   ├── everforest/
   ├── kanagawa/
   ├── rose-pine/
   ├── matte-black/
   ├── osaka-jade/
   └── ristretto/
   ```

   Each theme folder contains WSL-relevant files only (no gnome.sh, tophat.sh, vscode.sh).

   For each theme, create:
   - `zellij.kdl` — from omakub
   - `btop.theme` — from omakub
   - `neovim.lua` — from omakub (LazyVim colorscheme override)
   - `alacritty.toml` — from omakub (for future terminal use)
   - `starship.toml` — custom per theme (palettes matching the theme)

9. **Create `scripts/theme.sh`** — interactive theme switcher:
   - Uses `gum choose` to pick a theme
   - Copies theme files to the right stow targets:
     - `zellij.kdl` → `~/.config/zellij/themes/<theme>.kdl` + updates `config.kdl` theme line
     - `btop.theme` → `~/.config/btop/themes/<theme>.theme` + updates `btop.conf` color_theme
     - `neovim.lua` → `~/.config/nvim/lua/plugins/theme.lua`
     - `starship.toml` → `~/.config/starship.toml`
   - Updates fzf `FZF_DEFAULT_OPTS` colors to match theme (via a shared env file or sed)

### Phase 4: Modular Install Scripts

10. **Restructure `install/` directory:**
    ```
    install/
    ├── terminal/               # runs on ALL platforms (WSL, native Linux, macOS)
    │   ├── required/
    │   │   └── app-gum.sh      # gum first (needed for UI)
    │   ├── app-zsh.sh
    │   ├── app-mise.sh         # mise (replaces NVM, SDKMAN)
    │   ├── app-zellij.sh
    │   ├── app-tmux.sh         # TPM install
    │   ├── app-neovim.sh
    │   ├── app-fzf.sh          # latest from GitHub
    │   ├── apps-cli.sh         # bat, eza, ripgrep, zoxide, jq, etc.
    │   ├── select-language.sh  # gum menu: Node.js, Java, Python, Go, Rust, etc.
    │   └── docker.sh           # optional, prompted
    ├── desktop/                # only runs on GNOME/desktop Linux
    │   ├── app-alacritty.sh
    │   └── set-gnome-*.sh
    └── agents.sh               # coding agents (moved from current location)
    ```

    Each `app-*.sh` is self-contained: check if installed, install if not, idempotent.

11. **Rewrite `bootstrap.sh`:**
    - ASCII art header (custom for dotfiles)
    - OS detection (WSL, Ubuntu, Arch, macOS stub)
    - Interactive gum menus for:
      - Language selection (Node.js, Java, Python, Go, Rust)
      - Optional tools (Docker, coding agents)
    - Source terminal installers in a loop
    - If GNOME detected, source desktop installers in a loop
    - Stow all configs
    - Set default shell to zsh
    - Run theme setup (default: catppuccin)

12. **Rewrite `scripts/update.sh`:**
    - System update (apt/pacman/brew based on OS)
    - Zinit plugin update
    - mise tool update (`mise up`)
    - Gum spin UI for progress

### Phase 5: CLI Command

13. **Create `bin/dotfiles`** — menu-driven CLI (inspired by omakub's `omakub` bin):
    ```
    dotfiles              # opens main menu
    dotfiles theme        # theme switcher
    dotfiles update       # run updates
    dotfiles install      # install additional tools
    ```
    Uses gum for all menus. Add `~/.local/bin/dotfiles` symlink via stow.

### Phase 6: Cleanup & Docs

14. **Update `.gitignore`** — add new stow package patterns
15. **Update `README.md`** — document new structure, themes, CLI, mise
16. **Update `AGENTS.md`** — reflect new install structure and conventions
17. **Update `bootstrap.sh` stow list** — add zellij, fastfetch, btop, bin
18. **Test dry-run** — `./bootstrap.sh --dry-run --skip-packages` to verify stow targets

## Current Step

All phases complete. Ready for testing and PR.
