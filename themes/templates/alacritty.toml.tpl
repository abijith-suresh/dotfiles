{{#if alacritty_has_root_colors}}[colors]
{{/if}}[colors.primary]
background = {{ alacritty_colors_primary_background }}
foreground = {{ alacritty_colors_primary_foreground }}
{{#if alacritty_colors_primary_dim_foreground}}dim_foreground = {{ alacritty_colors_primary_dim_foreground }}
{{/if}}{{#if alacritty_colors_primary_bright_foreground}}bright_foreground = {{ alacritty_colors_primary_bright_foreground }}
{{/if}}
{{#if alacritty_colors_cursor_text}}[colors.cursor]
text = {{ alacritty_colors_cursor_text }}
cursor = {{ alacritty_colors_cursor_cursor }}

{{/if}}{{#if alacritty_colors_vi_mode_cursor_text}}[colors.vi_mode_cursor]
text = {{ alacritty_colors_vi_mode_cursor_text }}
cursor = {{ alacritty_colors_vi_mode_cursor_cursor }}

{{/if}}{{#if alacritty_colors_search_matches_foreground}}[colors.search.matches]
foreground = {{ alacritty_colors_search_matches_foreground }}
background = {{ alacritty_colors_search_matches_background }}

{{/if}}{{#if alacritty_colors_search_focused_match_foreground}}[colors.search.focused_match]
foreground = {{ alacritty_colors_search_focused_match_foreground }}
background = {{ alacritty_colors_search_focused_match_background }}

{{/if}}{{#if alacritty_colors_hints_start_foreground}}[colors.hints.start]
foreground = {{ alacritty_colors_hints_start_foreground }}
background = {{ alacritty_colors_hints_start_background }}

{{/if}}{{#if alacritty_colors_hints_end_foreground}}[colors.hints.end]
foreground = {{ alacritty_colors_hints_end_foreground }}
background = {{ alacritty_colors_hints_end_background }}

{{/if}}{{#if alacritty_colors_line_indicator_foreground}}[colors.line_indicator]
foreground = {{ alacritty_colors_line_indicator_foreground }}
background = {{ alacritty_colors_line_indicator_background }}

{{/if}}{{#if alacritty_colors_footer_bar_foreground}}[colors.footer_bar]
foreground = {{ alacritty_colors_footer_bar_foreground }}
background = {{ alacritty_colors_footer_bar_background }}

{{/if}}[colors.selection]
{{#if alacritty_colors_selection_text}}text = {{ alacritty_colors_selection_text }}
{{/if}}{{#if alacritty_colors_selection_foreground}}foreground = {{ alacritty_colors_selection_foreground }}
{{/if}}background = {{ alacritty_colors_selection_background }}

[colors.normal]
black = {{ alacritty_colors_normal_black }}
red = {{ alacritty_colors_normal_red }}
green = {{ alacritty_colors_normal_green }}
yellow = {{ alacritty_colors_normal_yellow }}
blue = {{ alacritty_colors_normal_blue }}
magenta = {{ alacritty_colors_normal_magenta }}
cyan = {{ alacritty_colors_normal_cyan }}
white = {{ alacritty_colors_normal_white }}

{{#if alacritty_colors_bright_black}}[colors.bright]
black = {{ alacritty_colors_bright_black }}
red = {{ alacritty_colors_bright_red }}
green = {{ alacritty_colors_bright_green }}
yellow = {{ alacritty_colors_bright_yellow }}
blue = {{ alacritty_colors_bright_blue }}
magenta = {{ alacritty_colors_bright_magenta }}
cyan = {{ alacritty_colors_bright_cyan }}
white = {{ alacritty_colors_bright_white }}

{{/if}}{{#if alacritty_colors_dim_black}}[colors.dim]
black = {{ alacritty_colors_dim_black }}
red = {{ alacritty_colors_dim_red }}
green = {{ alacritty_colors_dim_green }}
yellow = {{ alacritty_colors_dim_yellow }}
blue = {{ alacritty_colors_dim_blue }}
magenta = {{ alacritty_colors_dim_magenta }}
cyan = {{ alacritty_colors_dim_cyan }}
white = {{ alacritty_colors_dim_white }}

{{/if}}{{#if alacritty_indexed_color_16}}[[colors.indexed_colors]]
index = 16
color = {{ alacritty_indexed_color_16 }}

{{/if}}{{#if alacritty_indexed_color_17}}[[colors.indexed_colors]]
index = 17
color = {{ alacritty_indexed_color_17 }}

{{/if}}{{#if alacritty_font_size}}[font]
size = {{ alacritty_font_size }}
{{/if}}
