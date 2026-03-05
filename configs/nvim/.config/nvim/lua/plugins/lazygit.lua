return {
  'kdheepak/lazygit.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  cmd = 'LazyGit',
  keys = {
    { '<leader>lg', '<cmd>LazyGit<CR>', desc = 'LazyGit' },
  },
  config = function()
    vim.g.lazygit_floating_window_border_chars = { '┌', '─', '┐', '│', '┘', '─', '└', '│' }
    vim.g.lazygit_floating_window_scaling_factor = 0.9
    vim.g.lazygit_floating_window_use_plenary = 0
    local autocmd = vim.api.nvim_create_autocmd
    autocmd('TermOpen', {
      group = vim.api.nvim_create_augroup('LazyGitGroup', { clear = true }),
      pattern = 'term://*lazygit',
      callback = function()
        vim.cmd.highlight('link Terminal Normal')
        vim.api.nvim_win_set_option(0, 'winblend', 0)
      end,
    })
  end,
}
