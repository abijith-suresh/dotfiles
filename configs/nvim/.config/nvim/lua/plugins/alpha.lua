return {
  "goolord/alpha-nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    dashboard.section.header.val = {
      " ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
      " ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
      " ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
      " ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
      " ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
      " ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
    }

    dashboard.section.buttons.val = {
      dashboard.button("e", "  New file", "<cmd>ene<CR>"),
      dashboard.button("SPC f f", "  Find file", "<cmd>Telescope find_files<CR>"),
      dashboard.button("SPC f r", "  Recent files", "<cmd>Telescope oldfiles<CR>"),
      dashboard.button("SPC f g", "  Find text", "<cmd>Telescope live_grep<CR>"),
      dashboard.button("SPC e", "  Explorer", "<cmd>Neotree toggle<CR>"),
      dashboard.button("q", "  Quit NVIM", "<cmd>qa<CR>"),
    }

    dashboard.section.footer.val = {
      "",
      "Neovim loaded successfully!",
    }

    dashboard.opts.opts.noautocmd = true
    alpha.setup(dashboard.opts)

    vim.api.nvim_create_autocmd("User", {
      pattern = "LazyVimStarted",
      callback = function()
        local stats = require("lazy").stats()
        local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
        dashboard.section.footer.val = {
          "",
          "⚡ Neovim loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms .. "ms",
        }
        pcall(vim.cmd.AlphaRedraw)
      end,
    })
  end,
}
