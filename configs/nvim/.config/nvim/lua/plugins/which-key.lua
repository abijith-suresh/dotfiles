-- Which-key
local wk = require("which-key")
wk.setup({
  preset = "modern",
  delay = function(ctx)
    return ctx.plugin and 0 or 200
  end,
  plugins = {
    marks = true,
    registers = true,
    spelling = {
      enabled = true,
      suggestions = 20,
    },
    presets = {
      operators = true,
      motions = true,
      text_objects = true,
      windows = true,
      nav = true,
      z = true,
      g = true,
    },
  },
  win = {
    no_overlap = true,
    padding = { 1, 2 },
    title = true,
    title_pos = "center",
  },
  layout = {
    width = { min = 20 },
    spacing = 3,
  },
  icons = {
    breadcrumb = "»",
    separator = "➜",
    group = "+",
  },
  show_help = true,
  show_keys = true,
})

-- Keymaps
vim.keymap.set("n", "<leader>?", function()
  require("which-key").show({ global = false })
end, { desc = "Buffer Local Keymaps (which-key)" })

-- Group descriptions
wk.add({
  { "<leader>b", group = "Buffer" },
  { "<leader>d", group = "Diagnostics" },
  { "<leader>g", group = "Git" },
  { "<leader>h", group = "Help/Hunk" },
  { "<leader>s", group = "Search/Session" },
  { "<leader>t", group = "Toggle/Tab" },
  { "<leader>v", group = "Window/Split" },
})
