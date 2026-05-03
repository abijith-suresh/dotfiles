-- Colorscheme
require("catppuccin").setup({
  flavour = "mocha",
  background = {
    light = "latte",
    dark = "mocha",
  },
  transparent_background = false,
  term_colors = true,
  show_end_of_buffer = false,
  dim_inactive = {
    enabled = false,
    shade = "dark",
    percentage = 0.15,
  },
  no_italic = false,
  no_bold = false,
  no_underline = false,
  default_integrations = true,
  auto_integrations = true,
  integrations = {
    gitsigns = true,
    indent_blankline = {
      enabled = true,
      colored_indent_levels = false,
    },
    mini = {
      enabled = true,
      indentscope_color = "",
    },
    native_lsp = {
      enabled = true,
      inlay_hints = {
        background = true,
      },
    },
    neotree = true,
    render_markdown = true,
    telescope = {
      enabled = true,
    },
    treesitter = true,
  },
})
vim.cmd.colorscheme("catppuccin")
