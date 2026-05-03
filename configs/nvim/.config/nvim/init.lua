require("core.options")
require("core.keymaps")
require("core.snippets")

-- Short helper for GitHub sources
local gh = function(repo)
  return "https://github.com/" .. repo
end

-- Install and load plugins via vim.pack
vim.pack.add({
  -- Theme
  { src = gh("catppuccin/nvim"), name = "catppuccin" },

  -- Fuzzy finder
  gh("nvim-telescope/telescope.nvim"),
  { src = gh("nvim-telescope/telescope-fzf-native.nvim"), name = "telescope-fzf-native.nvim" },
  gh("nvim-telescope/telescope-ui-select.nvim"),

  -- Syntax & textobjects
  gh("nvim-treesitter/nvim-treesitter"),
  gh("nvim-treesitter/nvim-treesitter-textobjects"),

  -- LSP
  gh("neovim/nvim-lspconfig"),

  -- Git
  gh("lewis6991/gitsigns.nvim"),

  -- Statusline
  gh("nvim-lualine/lualine.nvim"),

  -- File explorer
  { src = gh("nvim-neo-tree/neo-tree.nvim"), name = "neo-tree" },

  -- Directory editing
  gh("stevearc/oil.nvim"),

  -- Indent guides
  gh("lukas-reineke/indent-blankline.nvim"),

  -- Keymap discovery
  gh("folke/which-key.nvim"),

  -- Surround editing
  gh("tpope/vim-surround"),

  -- Commenting
  gh("numToStr/Comment.nvim"),

  -- Autopairs
  gh("windwp/nvim-autopairs"),

  -- Todo highlighting
  { src = gh("folke/todo-comments.nvim"), name = "todo-comments.nvim" },

  -- Quick file switching
  { src = gh("ThePrimeagen/harpoon"), name = "harpoon", version = "harpoon2" },

  -- LazyGit integration
  gh("kdheepak/lazygit.nvim"),

  -- Markdown rendering
  gh("MeanderingProgrammer/render-markdown.nvim"),

  -- Tmux navigation
  gh("christoomey/vim-tmux-navigator"),

  -- Icons
  gh("nvim-tree/nvim-web-devicons"),

  -- UI select
  gh("nvim-lua/plenary.nvim"),

  -- UI components
  gh("MunifTanjim/nui.nvim"),

  -- LSP progress
  { src = gh("j-hui/fidget.nvim"), name = "fidget.nvim" },
})

-- Configure plugins
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

-- LSP server configs & enable
-- Servers with configs provided by nvim-lspconfig's lsp/ directory
-- only need vim.lsp.enable() — no custom cmd/filetype/root_markers needed
vim.lsp.enable("lua_ls")
vim.lsp.enable("pyright")
vim.lsp.enable("ruff")
vim.lsp.enable("ts_ls")
vim.lsp.enable("html")
vim.lsp.enable("cssls")
vim.lsp.enable("jsonls")
vim.lsp.enable("bashls")
vim.lsp.enable("yamlls")
vim.lsp.enable("dockerls")
vim.lsp.enable("docker_compose_language_service")

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
      end, { buffer = event.buf, desc = "[T]oggle Inlay [H]ints" })
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
