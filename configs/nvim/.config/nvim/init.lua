require("core.options")
require("core.keymaps")
require("core.snippets")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Setup plugins
require("lazy").setup({
  require("plugins.colorscheme"),
  require("plugins.telescope"),
  require("plugins.treesitter"),
  require("plugins.lsp"),
  require("plugins.autocompletion"),
  require("plugins.none-ls"),
  require("plugins.lualine"),
  require("plugins.neo-tree"),
  require("plugins.oil"),
  require("plugins.alpha"),
  require("plugins.indent-blankline"),
  require("plugins.gitsigns"),
  require("plugins.vim-tmux-navigator"),
  require("plugins.which-key"),
  require("plugins.misc"),
  require("plugins.harpoon"),
  require("plugins.lazygit"),
  require("plugins.render-markdown"),
  require("plugins.bufferline"),
}, {
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = "⌘",
      config = "🛠",
      event = "📅",
      ft = "📂",
      init = "⚙",
      keys = "🗝",
      plugin = "🔌",
      runtime = "💻",
      require = "🌙",
      source = "📄",
      start = "🚀",
      task = "📌",
      lazy = "💤 ",
    },
  },
})

-- Function to check if a file exists
local function file_exists(file)
  local f = io.open(file, "r")
  if f then
    f:close()
    return true
  else
    return false
  end
end

-- Path to the session file
local session_file = ".session.vim"

-- Check if the session file exists in the current directory
if file_exists(session_file) then
  vim.cmd("source " .. session_file)
end
