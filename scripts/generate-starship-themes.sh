#!/usr/bin/env bash
# scripts/generate-starship-themes.sh
# Generates complete starship.toml files for each theme with embedded palette
# Run from repo root: bash scripts/generate-starship-themes.sh

set -e

THEMES_DIR="$(cd "$(dirname "$0")/.." && pwd)/themes"

# Common starship format/layout (same for all themes)
read -r -d '' STARSHIP_HEADER << 'HEADER' || true
format = """
$directory\
$git_branch\
$git_status\
$fill\
$python\
$lua\
$nodejs\
$golang\
$haskell\
$rust\
$ruby\
$package\
$docker_context\
$jobs\
$cmd_duration\
$line_break\
$character"""

add_newline = true
HEADER

read -r -d '' STARSHIP_MODULES << 'MODULES' || true
[directory]
style = 'bold fg:blue'
format = '[$path ]($style)'
truncation_length = 3
truncation_symbol = '…/'
truncate_to_repo = false

[directory.substitutions]
'Documents' = '󰈙'
'Downloads' = ' '
'Music' = ' '
'Pictures' = ' '

[git_branch]
style = 'fg:green'
symbol = ' '
format = '[on](white) [$symbol$branch ]($style)'

[git_status]
style = 'fg:green'
format = '([$all_status$ahead_behind]($style) )'

[fill]
symbol = ' '

[python]
style = 'teal'
symbol = ' '
format = '[${symbol}${pyenv_prefix}(${version} )(\($virtualenv\) )]($style)'
pyenv_version_name = true
pyenv_prefix = ''

[lua]
symbol = ' '

[nodejs]
style = 'blue'
symbol = ' '

[golang]
style = 'blue'
symbol = ' '

[rust]
style = 'orange'
symbol = ' '

[package]
symbol = '󰏗 '

[docker_context]
symbol = ' '
style = 'fg:#06969A'
format = '[$symbol]($style) $path'
detect_files = ['docker-compose.yml', 'docker-compose.yaml', 'Dockerfile']
detect_extensions = ['Dockerfile']

[jobs]
symbol = ' '
style = 'red'
number_threshold = 1
format = '[$symbol]($style)'

[cmd_duration]
min_time = 500
style = 'fg:gray'
format = '[$duration]($style)'
MODULES

# Theme palette definitions
declare -A PALETTES

PALETTES[catppuccin]='
palette = "catppuccin_mocha"

[palettes.catppuccin_mocha]
rosewater = "#f5e0dc"
flamingo = "#f2cdcd"
pink = "#f5c2e7"
mauve = "#cba6f7"
red = "#f38ba8"
maroon = "#eba0ac"
peach = "#fab387"
yellow = "#f9e2af"
green = "#a6e3a1"
teal = "#94e2d5"
sky = "#89dceb"
sapphire = "#74c7ec"
blue = "#89b4fa"
lavender = "#b4befe"
text = "#cdd6f4"
subtext1 = "#bac2de"
subtext0 = "#a6adc8"
overlay2 = "#9399b2"
overlay1 = "#7f849c"
overlay0 = "#6c7086"
surface2 = "#585b70"
surface1 = "#45475a"
surface0 = "#313244"
base = "#1e1e2e"
mantle = "#181825"
crust = "#11111b"'

PALETTES[tokyo-night]='
palette = "tokyo_night"

[palettes.tokyo_night]
rosewater = "#c0caf5"
pink = "#bb9af7"
mauve = "#bb9af7"
lavender = "#bb9af7"
red = "#f7768e"
maroon = "#db4b4b"
peach = "#ff9e64"
yellow = "#e0af68"
green = "#9ece6a"
teal = "#73daca"
sky = "#7dcfff"
sapphire = "#7aa2f7"
blue = "#7aa2f7"
text = "#a9b1d6"
subtext1 = "#9aa5ce"
subtext0 = "#565f89"
overlay2 = "#414868"
overlay1 = "#2f3549"
overlay0 = "#24283b"
surface2 = "#1f2335"
surface1 = "#1a1b26"
surface0 = "#13161c"
base = "#1a1b26"
mantle = "#16161e"
crust = "#13131a"'

PALETTES[gruvbox]='
palette = "gruvbox"

[palettes.gruvbox]
rosewater = "#ebdbb2"
pink = "#d3869b"
mauve = "#d3869b"
lavender = "#b16286"
red = "#fb4934"
maroon = "#cc241d"
peach = "#fe8019"
yellow = "#fabd2f"
green = "#b8bb26"
teal = "#8ec07c"
sky = "#83a598"
sapphire = "#83a598"
blue = "#83a598"
text = "#ebdbb2"
subtext1 = "#d5c4a1"
subtext0 = "#bdae93"
overlay2 = "#a89984"
overlay1 = "#928374"
overlay0 = "#665c54"
surface2 = "#504945"
surface1 = "#3c3836"
surface0 = "#282828"
base = "#282828"
mantle = "#1d2021"
crust = "#1d2021"'

PALETTES[nord]='
palette = "nord"

[palettes.nord]
rosewater = "#eceff4"
pink = "#b48ead"
mauve = "#b48ead"
lavender = "#b48ead"
red = "#bf616a"
maroon = "#bf616a"
peach = "#d08770"
yellow = "#ebcb8b"
green = "#a3be8c"
teal = "#8fbcbb"
sky = "#88c0d0"
sapphire = "#81a1c1"
blue = "#81a1c1"
text = "#eceff4"
subtext1 = "#d8dee9"
subtext0 = "#81a1c1"
overlay2 = "#616e88"
overlay1 = "#4c566a"
overlay0 = "#434c5e"
surface2 = "#3b4252"
surface1 = "#2e3440"
surface0 = "#2e3440"
base = "#2e3440"
mantle = "#2e3440"
crust = "#2e3440"'

PALETTES[everforest]='
palette = "everforest"

[palettes.everforest]
rosewater = "#d3c6aa"
pink = "#d699b6"
mauve = "#d699b6"
lavender = "#d699b6"
red = "#e67e80"
maroon = "#e67e80"
peach = "#e69875"
yellow = "#dbbc7f"
green = "#a7c080"
teal = "#83c092"
sky = "#7fbbb3"
sapphire = "#7fbbb3"
blue = "#7fbbb3"
text = "#d3c6aa"
subtext1 = "#a7c080"
subtext0 = "#9da9a0"
overlay2 = "#859289"
overlay1 = "#5c6a72"
overlay0 = "#4b565c"
surface2 = "#374145"
surface1 = "#2d353b"
surface0 = "#272e33"
base = "#272e33"
mantle = "#1e2326"
crust = "#1e2326"'

PALETTES[kanagawa]='
palette = "kanagawa"

[palettes.kanagawa]
rosewater = "#dcd7ba"
pink = "#d27e99"
mauve = "#957fb8"
lavender = "#9cabca"
red = "#c34043"
maroon = "#e82424"
peach = "#e98a3a"
yellow = "#c0a36e"
green = "#76946a"
teal = "#6a9589"
sky = "#7fb4ca"
sapphire = "#7e9cd8"
blue = "#7e9cd8"
text = "#dcd7ba"
subtext1 = "#c8c093"
subtext0 = "#727169"
overlay2 = "#54546d"
overlay1 = "#54546d"
overlay0 = "#363646"
surface2 = "#2a2a37"
surface1 = "#223249"
surface0 = "#1f1f28"
base = "#1f1f28"
mantle = "#16161d"
crust = "#16161d"'

PALETTES[rose-pine]='
palette = "rose_pine"

[palettes.rose_pine]
rosewater = "#e0def4"
pink = "#eb6f92"
mauve = "#c4a7e7"
lavender = "#c4a7e7"
red = "#eb6f92"
maroon = "#eb6f92"
peach = "#ea9a97"
yellow = "#f6c177"
green = "#9ccfd8"
teal = "#9ccfd8"
sky = "#9ccfd8"
sapphire = "#c4a7e7"
blue = "#c4a7e7"
text = "#e0def4"
subtext1 = "#908caa"
subtext0 = "#6e6a86"
overlay2 = "#56527e"
overlay1 = "#44415a"
overlay0 = "#393552"
surface2 = "#26233a"
surface1 = "#1f1d30"
surface0 = "#191724"
base = "#191724"
mantle = "#1f1d2e"
crust = "#191724"'

PALETTES[matte-black]='
palette = "matte_black"

[palettes.matte_black]
rosewater = "#c8c8c8"
pink = "#d4756e"
mauve = "#af8fd4"
lavender = "#af8fd4"
red = "#d4756e"
maroon = "#b45050"
peach = "#d49f6e"
yellow = "#d4b475"
green = "#8faf77"
teal = "#77c7af"
sky = "#8fafd4"
sapphire = "#8fafd4"
blue = "#8fafd4"
text = "#c8c8c8"
subtext1 = "#a0a0a0"
subtext0 = "#787878"
overlay2 = "#585858"
overlay1 = "#404040"
overlay0 = "#303030"
surface2 = "#262626"
surface1 = "#1e1e1e"
surface0 = "#1a1a1a"
base = "#1a1a1a"
mantle = "#161616"
crust = "#131313"'

PALETTES[osaka-jade]='
palette = "osaka_jade"

[palettes.osaka_jade]
rosewater = "#c8c8c8"
pink = "#c470a8"
mauve = "#a870c4"
lavender = "#a870c4"
red = "#c47070"
maroon = "#a85050"
peach = "#c49070"
yellow = "#c4b070"
green = "#6ea878"
teal = "#70c4a8"
sky = "#70a8c4"
sapphire = "#70a8c4"
blue = "#70a8c4"
text = "#c8c8c8"
subtext1 = "#989898"
subtext0 = "#707070"
overlay2 = "#585858"
overlay1 = "#404040"
overlay0 = "#303030"
surface2 = "#283430"
surface1 = "#1e2a28"
surface0 = "#182220"
base = "#182220"
mantle = "#141a18"
crust = "#101614"'

PALETTES[ristretto]='
palette = "ristretto"

[palettes.ristretto]
rosewater = "#e0d0c0"
pink = "#d4756e"
mauve = "#af8fd4"
lavender = "#af8fd4"
red = "#d4756e"
maroon = "#b85050"
peach = "#d49f6e"
yellow = "#d4b475"
green = "#8faf77"
teal = "#75d4b4"
sky = "#8fafd4"
sapphire = "#8fafd4"
blue = "#8fafd4"
text = "#e0d0c0"
subtext1 = "#b8a898"
subtext0 = "#908070"
overlay2 = "#605040"
overlay1 = "#483828"
overlay0 = "#382818"
surface2 = "#302018"
surface1 = "#281810"
surface0 = "#201008"
base = "#201008"
mantle = "#180c06"
crust = "#100804"'

# Generate files — palette must come after header but before module sections
for theme in "${!PALETTES[@]}"; do
  target="$THEMES_DIR/$theme/starship.toml"
  # Write: header → palette → modules
  echo "$STARSHIP_HEADER" > "$target"
  echo "${PALETTES[$theme]}" >> "$target"
  echo "$STARSHIP_MODULES" >> "$target"
  echo "Generated $target"
done
