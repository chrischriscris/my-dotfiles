local plugins = {
	{ "folke/neoconf.nvim" },
	{ "folke/neodev.nvim" },
	{
		"nvim-telescope/telescope.nvim",
		version = "0.1.5",
		dependencies = {
			{ "nvim-lua/popup.nvim" },
			{ "nvim-lua/plenary.nvim" },
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
	},

	-- Theme/UI
	{ "ellisonleao/gruvbox.nvim", priority = 999, config = true },
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			vim.cmd("colorscheme catppuccin-mocha")
			-- Transparent background
			-- vim.cmd("highlight Normal guibg=NONE ctermbg=NONE")
		end,
	},

	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {},
	},

	-- Treesitter
	{ { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" } },
	{ "nvim-treesitter/playground" },

	-- Utilities
	{ "theprimeagen/harpoon" },
	{ "theprimeagen/refactoring.nvim" },
	{ "mbbill/undotree" },
	{ "nvim-treesitter/nvim-treesitter-context" },
	{ "tpope/vim-fugitive" },
	{
		"kdheepak/lazygit.nvim",
		cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile", "LazyGitFilter", "LazyGitFilterCurrentFile" },
		-- optional for floating window border decoration
		dependencies = { "nvim-lua/plenary.nvim" },
		-- setting the keybinding for LazyGit with 'keys' is recommended in
		-- order to load the plugin when the command is run for the first time
		keys = {
			{ "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
		},
	},
	{
		"MeanderingProgrammer/render-markdown.nvim",
		opts = {},
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
	},
	{
		"andrewferrier/debugprint.nvim",
		dependencies = {
			"echasnovski/mini.nvim", -- Needed for :ToggleCommentDebugPrints(NeoVim 0.9 only)
			-- and line highlighting (optional)
		},
		lazy = false, -- Required to make line highlighting work before debugprint is first used
		version = "*", -- Remove if you DON'T want to use the stable version
	},

	-- LSP
	{ "williamboman/mason.nvim" },
	{ "williamboman/mason-lspconfig.nvim" },
	{ "VonHeikemen/lsp-zero.nvim", branch = "v3.x" },
	{ "neovim/nvim-lspconfig" },
	{ "hrsh7th/cmp-nvim-lsp" },
	{ "hrsh7th/nvim-cmp" },
	{ "L3MON4D3/LuaSnip" },
	{ "github/copilot.vim" },
    {
      {
        "CopilotC-Nvim/CopilotChat.nvim",
        dependencies = {
          { "github/copilot.vim" }, -- or zbirenbaum/copilot.lua
          { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
        },
        build = "make tiktoken", -- Only on MacOS or Linux
        opts = {
          -- See Configuration section for options
        },
        -- See Commands section for default commands if you want to lazy load on them
      },
    },
	{ "eandrju/cellular-automaton.nvim" },
	{ "laytan/cloak.nvim" },
	{ "kaarmu/typst.vim", ft = "typst", lazy = false },

	-- These optional plugins should be loaded directly because of a bug in Packer lazy loading
	{ "nvim-tree/nvim-web-devicons" },
	{ "nvimtools/none-ls.nvim" },

	-- Gitsigns
	{
		"lewis6991/gitsigns.nvim",
		requires = { "nvim-lua/plenary.nvim" },
		config = function()
			require("gitsigns").setup({ current_line_blame = true })
		end,
	},

	-- Surround
	{
		"kylechui/nvim-surround",
		version = "*",
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({})
		end,
	},
}

local opts = {}

require("lazy").setup(plugins, opts)
