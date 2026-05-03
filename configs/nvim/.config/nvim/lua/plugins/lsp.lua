-- LSP configuration
-- Server configs come from nvim-lspconfig's lsp/ directory (auto-discovered from runtimepath).
-- Server overrides and vim.lsp.enable() calls are in init.lua.
-- This file only sets up fidget.nvim for LSP progress notifications.

require("fidget").setup({
  notification = {
    window = {
      winblend = 0,
    },
  },
})
