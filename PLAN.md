# PLAN.md — Starship Prompt Improvements

## Goal

Improve information density, visual clarity, and cross-shell compatibility of the
starship prompt while keeping the pure preset two-line structure and Catppuccin Mocha
palette, based on findings from 8 reference configs (folke, omerxx, dreamsofcode,
jetpack preset, catppuccin-powerline, pure-preset, nerd-font-symbols, catppuccin/starship).

## Approach

Five targeted improvements derived from research:

1. **Git diff stats on line 1** — `$fill` + `$git_metrics` right-aligns `+N -N`
   on the directory/git line. Zero cost on a clean repo, instant signal on a dirty
   one. Seen in folke's config and the jetpack preset.

2. **Semantic per-indicator git status colors** — currently all git status indicators
   use one flat `fg:yellow`. Modified=yellow, staged=green, untracked=dimmed,
   deleted/behind/conflicted=red gives at-a-glance state at no extra visual cost.
   Pattern from folke.

3. **Double-icon fix** — the `${custom.git_host}` forge icon and `$git_branch`
   symbol sit back-to-back. Remove the branch symbol; the forge icon already
   contextualises "this is a git repo." Reduces `path 󰊤  branch` → `path 󰊤 branch`.

4. **`$cmd_duration` in left format** — currently in `right_format`, so it never
   shows in bash (no ble.sh). Moving it between `$line_break` and `$character`
   makes it universally visible: `2s ❯`.

5. **`$package` with version** — icon-only `󰏗` is redundant with the language icon.
   Showing `󰏗 1.2.3` makes it actually useful.

Also: `$git_state` color lifted from `fg:overlay1` (barely visible) to `fg:peach`
— rebasing/merging/cherry-picking is critical context and should catch the eye.

Not changing: two-line structure, Catppuccin palette, forge icon custom module, nerd
font glyph assignments, the 52-module right_format coverage (only fires when relevant).

## Steps

### 1. Restructure the left `format` string

Add `$fill\` and `$git_metrics\` between `$git_status` and `$line_break`.
Move `$cmd_duration\` between `$line_break` and `$character`.

```toml
format = """
$directory\
${custom.git_host}\
$git_branch\
$git_state\
$git_status\
$fill\
$git_metrics\
$line_break\
$cmd_duration\
$character"""
```

Result layout:
```
                                          ← blank line (add_newline = true)
…/reshrimp 󰊤 feat/branch !+                       +145 -23
2s ❯                                       [bun]  󰏗 1.2.3
```
(`$git_metrics` hidden when repo is clean. `$cmd_duration` hidden when last
command ran under 500 ms.)

### 2. Add `[git_metrics]` section

Enable it and apply Catppuccin semantic colours:

```toml
[git_metrics]
added_style   = "fg:green"
deleted_style = "fg:red"
format        = "([+$added]($added_style) )([-$deleted]($deleted_style))"
disabled      = false
```

### 3. Fix `[git_branch]` double-icon

```toml
[git_branch]
symbol = ""
```

### 4. Upgrade `[git_status]` to per-indicator semantic colours

Remove the single outer `style = "fg:yellow"` approach and embed a semantic
colour directly in each indicator string. The format wrapper keeps its `($style)`
as a fallback for any unstyled content (starship preserves inline styles when
they're nested inside a format wrapper — verified from folke's config pattern).

```toml
[git_status]
style  = "fg:overlay1"
format = "[$all_status$ahead_behind]($style)"

conflicted = "[= ](fg:red)"
ahead      = "[⇡ ](fg:green)"
behind     = "[⇣ ](fg:red)"
diverged   = "[⇕ ](fg:yellow)"
untracked  = "[? ](fg:overlay1)"
stashed    = "[≡ ](fg:overlay1)"
modified   = "[! ](fg:yellow)"
staged     = "[+ ](fg:green)"
renamed    = "[» ](fg:blue)"
deleted    = "[✘ ](fg:red)"
```

Semantic logic:
- **red**: needs action (conflict, behind, deleted)
- **green**: healthy/ready (ahead, staged)
- **yellow**: caution/pending (modified, diverged)
- **overlay1**: low-noise context (untracked, stashed)
- **blue**: neutral file-system change (renamed)

### 5. Lift `[git_state]` colour

```toml
[git_state]
style = "fg:peach"
```

### 6. Move `[cmd_duration]` out of `right_format` into left format

- Remove `$cmd_duration\` from the `right_format` string (it's currently the
  last entry).
- The `[cmd_duration]` section format stays the same but update it to add a
  trailing space so it reads cleanly before `❯`:

```toml
[cmd_duration]
min_time = 500
style    = "fg:overlay1"
format   = "[$duration ](fg:overlay1)"
```

### 7. Show version in `[package]`

```toml
[package]
symbol = "󰏗 "
style  = "fg:overlay2"
format = "[$symbol$version]($style) "
```

## Current Step

<!-- leave blank — agent updates during build -->
