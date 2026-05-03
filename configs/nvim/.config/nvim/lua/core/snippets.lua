local function setup_diagnostics()
  vim.diagnostic.config({
    virtual_text = {
      prefix = "● ",
      format = function(diagnostic)
        return ("[%s] %s"):format(diagnostic.code, diagnostic.message)
      end,
    },
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = "✘",
        [vim.diagnostic.severity.WARN] = "▲",
        [vim.diagnostic.severity.INFO] = "◆",
        [vim.diagnostic.severity.HINT] = "→",
      },
    },
    float = { source = true, border = "rounded" },
  })
end

local function setup_yank_highlight()
  vim.api.nvim_create_augroup("YankHighlight", { clear = true })
  vim.api.nvim_create_autocmd("TextYankPost", {
    group = "YankHighlight",
    callback = function()
      vim.hl.on_yank()
    end,
  })
end

setup_diagnostics()
setup_yank_highlight()
