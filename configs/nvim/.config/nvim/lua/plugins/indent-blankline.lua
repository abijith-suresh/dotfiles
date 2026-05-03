-- Indent-blankline
require("ibl").setup({
  indent = {
    char = "│",
    tab_char = "│",
  },
  scope = {
    enabled = true,
    show_start = true,
    show_end = true,
    injected_languages = false,
    highlight = { "Function", "Label" },
    priority = 500,
  },
  exclude = {
    filetypes = {
      "help",
      "dashboard",
      "neo-tree",
      "Trouble",
      "trouble",
      "notify",
      "toggleterm",
      "lazyterm",
    },
  },
})
