return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000, -- ensure it loads first
		config = function()
			require("catppuccin").setup({
				flavour = "mocha",
				background = {
					light = "latte",
					dark = "mocha",
				},
				transparent_background = false,
				show_end_of_buffer = false,
				term_colors = true,
				integrations = {
					cmp = true,
					gitsigns = true,
					nvimtree = true,
					telescope = { enabled = true },
					treesitter = true,
					native_lsp = {
						enabled = true,
						underlines = {
							errors = { "undercurl" },
							hints = { "undercurl" },
							warnings = { "undercurl" },
							information = { "undercurl" },
						},
					},
				},
			})

			-- Load the Catppuccin colorscheme
			vim.cmd.colorscheme("catppuccin")
		end,
	},
}
