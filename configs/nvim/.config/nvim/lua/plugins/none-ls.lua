return {
  "nvimtools/none-ls.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvimtools/none-ls-extras.nvim",
  },
  config = function()
    local null_ls = require("null-ls")
    local formatting = null_ls.builtins.formatting
    local diagnostics = null_ls.builtins.diagnostics

    null_ls.setup({
      debug = false,
      sources = {
        formatting.prettier.with({
          extra_filetypes = { "toml" },
          extra_args = { "--no-semi", "--single-quote", "--jsx-single-quote" },
        }),
        formatting.stylua,
        formatting.shfmt,
        diagnostics.shellcheck,
      },
    })

    vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format, { desc = "Format" })
  end,
}
