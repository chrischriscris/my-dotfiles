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
        },
    },

    -- Theme/UI
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            vim.cmd("colorscheme catppuccin-mocha")
            -- Transparent background
            vim.cmd("highlight Normal guibg=NONE ctermbg=NONE")
        end,
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
    { "nvim-treesitter/nvim-treesitter-context" },
    -- { "tpope/vim-fugitive" },
    {
        "kdheepak/lazygit.nvim",
        cmd = {
            "LazyGit",
            "LazyGitConfig",
            "LazyGitCurrentFile",
            "LazyGitFilter",
            "LazyGitFilterCurrentFile",
        },
        -- optional for floating window border decoration
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        -- setting the keybinding for LazyGit with 'keys' is recommended in
        -- order to load the plugin when the command is run for the first time
        keys = {
            { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" }
        }
    },

    -- LSP
    { "williamboman/mason.nvim" },
    { "williamboman/mason-lspconfig.nvim" },
    { "VonHeikemen/lsp-zero.nvim",              branch = "v3.x" },
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
        config = function()
            require("nnn").setup()
        end,
    },
    { "kaarmu/typst.vim",           ft = "typst", lazy = false },
    -- These optional plugins should be loaded directly because of a bug in Packer lazy loading
    { "nvim-tree/nvim-web-devicons" },
    { "nvimtools/none-ls.nvim" },

    -- Gitsigns
    {
        "lewis6991/gitsigns.nvim",
        requires = { "nvim-lua/plenary.nvim" },
        config = function()
            require("gitsigns").setup({
                current_line_blame = true,
            })
        end,
    },

    -- Java LSP
    {
        "nvim-java/nvim-java",
        dependencies = {
            "nvim-java/lua-async-await",
            "nvim-java/nvim-java-core",
            "nvim-java/nvim-java-test",
            "nvim-java/nvim-java-dap",
            "MunifTanjim/nui.nvim",
            "neovim/nvim-lspconfig",
            "mfussenegger/nvim-dap",
            {
                "williamboman/mason.nvim",
                opts = {
                    registries = {
                        "github:nvim-java/mason-registry",
                        "github:mason-org/mason-registry",
                    },
                },
            },
        },
    },
}

local opts = {}

require("lazy").setup(plugins, opts)
