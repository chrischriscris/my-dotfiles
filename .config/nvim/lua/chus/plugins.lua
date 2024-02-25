local plugins = {
    { "folke/which-key.nvim" },
    { "folke/neoconf.nvim" },
    { "folke/neodev.nvim" },
    {
        "nvim-telescope/telescope.nvim",
        version = "0.1.5",
        dependencies = {
            { "nvim-lua/popup.nvim" },
            { "nvim-lua/plenary.nvim" },
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        }
    },

    -- Theme/UI
    {
        "rose-pine/neovim",
        name = "rose-pine",
        config = function()
            vim.cmd("colorscheme rose-pine")
        end
    },
    {
        "folke/trouble.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            -- your configuration comes here
            -- or leave it empty to use the default settings
            -- refer to the configuration section below
        },
    },

    -- Treesitter
    { { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" } },
    { "nvim-treesitter/playground" },

    -- Utilities
    { "theprimeagen/harpoon" },
    { "theprimeagen/refactoring.nvim" },
    { "mbbill/undotree" },
    { "tpope/vim-fugitive" },
    { "nvim-treesitter/nvim-treesitter-context" },

    -- LSP
    { "williamboman/mason.nvim" },
    { "williamboman/mason-lspconfig.nvim" },
    { "VonHeikemen/lsp-zero.nvim",                               branch = "v3.x" },
    { "neovim/nvim-lspconfig" },
    { "hrsh7th/cmp-nvim-lsp" },
    { "hrsh7th/nvim-cmp" },
    { "L3MON4D3/LuaSnip" },
    -- {
    --     dependencies = {
    --         { "williamboman/mason-lspconfig.nvim" },

    --         -- Autocompletion
    --         { "hrsh7th/cmp-buffer" },
    --         { "hrsh7th/cmp-path" },
    --         { "saadparwaiz1/cmp_luasnip" },
    --         { "hrsh7th/cmp-nvim-lua" },

    --         -- Snippets
    --         { "rafamadriz/friendly-snippets" },
    --     }
    -- },
    { "folke/zen-mode.nvim" },
    { "github/copilot.vim" },
    { "eandrju/cellular-automaton.nvim" },
    { "laytan/cloak.nvim" },
    { "lervag/vimtex" },
    {
        "luukvbaal/nnn.nvim",
        config = function() require("nnn").setup() end
    },
    { "kaarmu/typst.vim",           ft = "typst", lazy = false },
    -- These optional plugins should be loaded directly because of a bug in Packer lazy loading
    { "nvim-tree/nvim-web-devicons" },
    { "lewis6991/gitsigns.nvim" },
    --  { "romgrk/barbar.nvim" },
    { "nvimtools/none-ls.nvim" }
}

local opts = {}

require("lazy").setup(plugins, opts)
