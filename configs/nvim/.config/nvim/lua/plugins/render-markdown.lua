return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  ft = { 'markdown' },
  opts = {
    sign = { enabled = false },
    completions = { lsp = { enabled = true } },
  },
}
