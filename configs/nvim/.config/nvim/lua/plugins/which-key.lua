-- Which-key
local wk = require("which-key")
wk.setup({ preset = "modern" })

-- Keymaps
vim.keymap.set("n", "<leader>?", function()
  require("which-key").show({ global = false })
end, { desc = "Show buffer keymaps" })

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
