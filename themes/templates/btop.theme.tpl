# Generated {{ display_name }} theme for btop

# Main background
theme[main_bg]="{{ btop_main_bg }}"

# Main text color
theme[main_fg]="{{ btop_main_fg }}"

# Title color for boxes
theme[title]="{{ btop_title }}"

# Highlight color for keyboard shortcuts
theme[hi_fg]="{{ btop_hi_fg }}"

# Background color of selected item in processes box
theme[selected_bg]="{{ btop_selected_bg }}"

# Foreground color of selected item in processes box
theme[selected_fg]="{{ btop_selected_fg }}"

# Color of inactive/disabled text
theme[inactive_fg]="{{ btop_inactive_fg }}"

{{#if btop_graph_text}}# Color of text appearing on top of graphs
theme[graph_text]="{{ btop_graph_text }}"

{{/if}}{{#if btop_meter_bg}}# Background color of the percentage meters
theme[meter_bg]="{{ btop_meter_bg }}"

{{/if}}# Misc colors for processes box
theme[proc_misc]="{{ btop_proc_misc }}"

# CPU, Memory, Network, Proc box outline colors
theme[cpu_box]="{{ btop_cpu_box }}"
theme[mem_box]="{{ btop_mem_box }}"
theme[net_box]="{{ btop_net_box }}"
theme[proc_box]="{{ btop_proc_box }}"

# Box divider line and small boxes line color
theme[div_line]="{{ btop_div_line }}"

# Temperature graph color (Green -> Yellow -> Red)
theme[temp_start]="{{ btop_temp_start }}"
theme[temp_mid]="{{ btop_temp_mid }}"
theme[temp_end]="{{ btop_temp_end }}"

# CPU graph colors
theme[cpu_start]="{{ btop_cpu_start }}"
theme[cpu_mid]="{{ btop_cpu_mid }}"
theme[cpu_end]="{{ btop_cpu_end }}"

# Mem/Disk free meter
theme[free_start]="{{ btop_free_start }}"
theme[free_mid]="{{ btop_free_mid }}"
theme[free_end]="{{ btop_free_end }}"

# Mem/Disk cached meter
theme[cached_start]="{{ btop_cached_start }}"
theme[cached_mid]="{{ btop_cached_mid }}"
theme[cached_end]="{{ btop_cached_end }}"

# Mem/Disk available meter
theme[available_start]="{{ btop_available_start }}"
theme[available_mid]="{{ btop_available_mid }}"
theme[available_end]="{{ btop_available_end }}"

# Mem/Disk used meter
theme[used_start]="{{ btop_used_start }}"
theme[used_mid]="{{ btop_used_mid }}"
theme[used_end]="{{ btop_used_end }}"

# Download graph colors
theme[download_start]="{{ btop_download_start }}"
theme[download_mid]="{{ btop_download_mid }}"
theme[download_end]="{{ btop_download_end }}"

# Upload graph colors
theme[upload_start]="{{ btop_upload_start }}"
theme[upload_mid]="{{ btop_upload_mid }}"
theme[upload_end]="{{ btop_upload_end }}"

{{#if btop_process_start}}# Process box color gradient
theme[process_start]="{{ btop_process_start }}"
theme[process_mid]="{{ btop_process_mid }}"
theme[process_end]="{{ btop_process_end }}"
{{/if}}
