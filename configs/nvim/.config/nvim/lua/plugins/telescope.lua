local actions = require("telescope.actions")
local builtin = require("telescope.builtin")

require("telescope").setup({
  defaults = {
    layout_strategy = "horizontal",
    layout_config = {
      horizontal = {
        prompt_position = "bottom",
        preview_width = 0.6,
        width = { padding = 0 },
        height = { padding = 0 },
      },
    },
    mappings = {
      i = {
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-j>"] = actions.move_selection_next,
        ["<C-l>"] = actions.select_default,
      },
      n = {
        ["q"] = actions.close,
      },
    },
  },
  pickers = {
    find_files = {
      file_ignore_patterns = { "node_modules", ".git", ".venv" },
      hidden = true,
    },
    buffers = {
      initial_mode = "normal",
      sort_lastused = true,
      mappings = {
        n = {
          ["d"] = actions.delete_buffer,
          ["l"] = actions.select_default,
        },
      },
    },
    marks = {
      initial_mode = "normal",
    },
    oldfiles = {
      initial_mode = "normal",
    },
  },
  live_grep = {
    file_ignore_patterns = { "node_modules", ".git", ".venv" },
    additional_args = function(_)
      return { "--hidden" }
    end,
  },
  path_display = {
    filename_first = {
      reverse_directories = true,
    },
  },
  extensions = {
    ["ui-select"] = {
      require("telescope.themes").get_dropdown(),
    },
  },
  git_files = {
    previewer = false,
  },
})

pcall(require("telescope").load_extension, "fzf")
pcall(require("telescope").load_extension, "ui-select")

vim.keymap.set("n", "<leader>sb", builtin.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<leader><tab>", builtin.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<leader>sm", builtin.marks, { desc = "Find marks" })
vim.keymap.set("n", "<leader>gf", builtin.git_files, { desc = "Find Git files" })
vim.keymap.set("n", "<leader>gc", builtin.git_commits, { desc = "Find Git commits" })
vim.keymap.set("n", "<leader>gcf", builtin.git_bcommits, { desc = "Find commits for this file" })
vim.keymap.set("n", "<leader>gb", builtin.git_branches, { desc = "Find Git branches" })
vim.keymap.set("n", "<leader>gs", builtin.git_status, { desc = "Show Git status" })
vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "Search help" })
vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "Search word under cursor" })
vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "Search file contents" })
vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "Find diagnostics" })
vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "Resume search" })
vim.keymap.set("n", "<leader>so", builtin.oldfiles, { desc = "Find recent files" })
vim.keymap.set("n", "<leader>sds", function()
  builtin.lsp_document_symbols({
    symbols = { "Class", "Function", "Method", "Constructor", "Interface", "Module", "Property" },
  })
end, { desc = "Find document symbols" })
vim.keymap.set("n", "<leader>s/", function()
  builtin.live_grep({
    grep_open_files = true,
    prompt_title = "Live Grep in Open Files",
  })
end, { desc = "Search open files" })
vim.keymap.set("n", "<leader>/", function()
  builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
    previewer = false,
  }))
end, { desc = "Search this buffer" })
