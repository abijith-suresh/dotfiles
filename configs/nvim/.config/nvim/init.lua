require("core.options")
require("core.keymaps")
require("core.snippets")

local function gh(repo)
  return "https://github.com/" .. repo
end

vim.pack.add({
  { src = gh("catppuccin/nvim"), name = "catppuccin" },
  gh("nvim-telescope/telescope.nvim"),
  { src = gh("nvim-telescope/telescope-fzf-native.nvim"), name = "telescope-fzf-native.nvim" },
  gh("nvim-telescope/telescope-ui-select.nvim"),
  gh("nvim-treesitter/nvim-treesitter"),
  gh("nvim-treesitter/nvim-treesitter-textobjects"),
  gh("neovim/nvim-lspconfig"),
  gh("lewis6991/gitsigns.nvim"),
  gh("nvim-lualine/lualine.nvim"),
  { src = gh("nvim-neo-tree/neo-tree.nvim"), name = "neo-tree" },
  gh("stevearc/oil.nvim"),
  gh("lukas-reineke/indent-blankline.nvim"),
  gh("folke/which-key.nvim"),
  gh("tpope/vim-surround"),
  gh("numToStr/Comment.nvim"),
  gh("windwp/nvim-autopairs"),
  { src = gh("folke/todo-comments.nvim"), name = "todo-comments.nvim" },
  { src = gh("ThePrimeagen/harpoon"), name = "harpoon", version = "harpoon2" },
  gh("kdheepak/lazygit.nvim"),
  gh("MeanderingProgrammer/render-markdown.nvim"),
  gh("christoomey/vim-tmux-navigator"),
  gh("nvim-tree/nvim-web-devicons"),
  gh("nvim-lua/plenary.nvim"),
  gh("MunifTanjim/nui.nvim"),
  { src = gh("j-hui/fidget.nvim"), name = "fidget.nvim" },
})

require("plugins.colorscheme")
require("plugins.telescope")
require("plugins.treesitter")
require("plugins.lsp")
require("plugins.lualine")
require("plugins.neo-tree")
require("plugins.oil")
require("plugins.indent-blankline")
require("plugins.gitsigns")
require("plugins.vim-tmux-navigator")
require("plugins.which-key")
require("plugins.misc")
require("plugins.harpoon")
require("plugins.lazygit")
require("plugins.render-markdown")

-- Server definitions come from nvim-lspconfig. Configure lua_ls below for editing this config.
vim.lsp.enable("lua_ls")
vim.lsp.enable("pyright")
vim.lsp.enable("ruff")
vim.lsp.enable("ts_ls")
vim.lsp.enable("html")
vim.lsp.enable("cssls")
vim.lsp.enable("jsonls")
vim.lsp.enable("bashls")
vim.lsp.enable("yamlls")

-- Override lua_ls for Neovim config development
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      completion = { callSnippet = "Replace" },
      runtime = { version = "LuaJIT" },
      workspace = {
        checkThirdParty = false,
        library = vim.api.nvim_get_runtime_file("", true),
      },
      diagnostics = {
        globals = { "vim" },
        disable = { "missing-fields" },
      },
      format = { enable = false },
    },
  },
})

-- LspAttach: completion, format-on-save, highlighting
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)

    -- Enable LSP-driven auto-completion
    if client and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, event.buf, {
        autotrigger = true,
      })
    end

    -- Format on save
    if client and client:supports_method("textDocument/formatting") then
      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = event.buf,
        callback = function()
          vim.lsp.buf.format({ bufnr = event.buf, async = false })
        end,
        group = vim.api.nvim_create_augroup("lsp-format-" .. event.buf, { clear = true }),
      })
    end

    -- Document highlighting
    if client and client:supports_method("textDocument/documentHighlight") then
      local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight-" .. event.buf, { clear = false })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })
    end

    -- Toggle inlay hints
    if client and client:supports_method("textDocument/inlayHint") then
      vim.keymap.set("n", "<leader>th", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
      end, { buffer = event.buf, desc = "Toggle inlay hints" })
    end
  end,
})

-- Source session file if it exists in current directory
local session_file = ".session.vim"
local f = io.open(session_file, "r")
if f then
  f:close()
  vim.cmd("source " .. session_file)
end
