require("oil").setup({
  default_file_explorer = false,
  columns = { "icon", "permissions", "size", "mtime" },
  keymaps = {
    ["g?"] = "actions.show_help",
    ["<C-v>"] = "actions.select_vsplit",
    ["<C-h>"] = "actions.select_split",
    ["<C-t>"] = "actions.select_tab",
    ["<C-c>"] = "actions.close",
    ["-"] = "actions.parent",
    ["_"] = "actions.open_cwd",
    ["`"] = "actions.cd",
    ["~"] = "actions.tcd",
    ["gs"] = "actions.change_sort",
    ["g."] = "actions.toggle_hidden",
    ["g\\"] = "actions.toggle_trash",
  },
  view_options = { natural_order = true },
  float = { border = "rounded" },
  confirmation = { border = "rounded" },
  progress = { border = "rounded" },
})

vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
