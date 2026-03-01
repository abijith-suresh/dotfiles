return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
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
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)
    
    -- Add group descriptions
    wk.add({
      { "<leader>b", group = "Buffer" },
      { "<leader>d", group = "Diagnostics" },
      { "<leader>f", group = "File/Find" },
      { "<leader>g", group = "Git" },
      { "<leader>h", group = "Help/Hunk" },
      { "<leader>l", group = "LSP" },
      { "<leader>s", group = "Search/Session" },
      { "<leader>t", group = "Toggle/Tab" },
      { "<leader>v", group = "Window/Split" },
      { "<leader>w", group = "Workspace" },
    })
  end,
}
