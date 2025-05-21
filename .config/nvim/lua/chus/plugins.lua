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
    {
        "ellisonleao/gruvbox.nvim",
        priority = 1000,
        config = true,
    },
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
    },
    {
        "loctvl842/monokai-pro.nvim",
        priority = 1000,
    },
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        opts = {},
    },
    {
        "nickkadutskyi/jb.nvim",
        lazy = false,
        priority = 1000,
        opts = {},
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
    {
        "catgoose/nvim-colorizer.lua",
        event = "BufReadPre",
        opts = { -- set to setup table
        },
    },

    -- LSP
    { "williamboman/mason.nvim" },
    { "williamboman/mason-lspconfig.nvim" },
    { "VonHeikemen/lsp-zero.nvim",        branch = "v3.x" },
    { "neovim/nvim-lspconfig" },
    { "hrsh7th/cmp-nvim-lsp" },
    { "hrsh7th/nvim-cmp" },

    -- TODO: CONFIGURE LATER
    -- {
    --     "saghen/blink.cmp",
    --     -- optional: provides snippets for the snippet source
    --     dependencies = { "rafamadriz/friendly-snippets" },

    --     -- use a release tag to download pre-built binaries
    --     version = "1.*",
    --     -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    --     -- build = 'cargo build --release',
    --     -- If you use nix, you can build from source using latest nightly rust with:
    --     -- build = 'nix run .#build-plugin',

    --     ---@module 'blink.cmp'
    --     ---@type blink.cmp.Config
    --     opts = {
    --         -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
    --         -- 'super-tab' for mappings similar to vscode (tab to accept)
    --         -- 'enter' for enter to accept
    --         -- 'none' for no mappings
    --         --
    --         -- All presets have the following mappings:
    --         -- C-space: Open menu or open docs if already open
    --         -- C-n/C-p or Up/Down: Select next/previous item
    --         -- C-e: Hide menu
    --         -- C-k: Toggle signature help (if signature.enabled = true)
    --         --
    --         -- See :h blink-cmp-config-keymap for defining your own keymap
    --         keymap = { preset = "default" },

    --         appearance = {
    --             -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
    --             -- Adjusts spacing to ensure icons are aligned
    --             nerd_font_variant = "mono",
    --         },

    --         -- (Default) Only show the documentation popup when manually triggered
    --         completion = { documentation = { auto_show = false } },

    --         -- Default list of enabled providers defined so that you can extend it
    --         -- elsewhere in your config, without redefining it, due to `opts_extend`
    --         sources = {
    --             default = { "lsp", "path", "snippets", "buffer" },
    --         },

    --         -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
    --         -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
    --         -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
    --         --
    --         -- See the fuzzy documentation for more information
    --         fuzzy = { implementation = "prefer_rust_with_warning" },
    --     },
    --     opts_extend = { "sources.default" },
    -- },
    -- {
    --     'neovim/nvim-lspconfig',
    --     dependencies = { 'saghen/blink.cmp' },

    --     -- example using `opts` for defining servers
    --     opts = {
    --         servers = {
    --             lua_ls = {}
    --         }
    --     },

    --     -- example calling setup directly for each LSP
    --     config = function()
    --         local capabilities = require('blink.cmp').get_lsp_capabilities()
    --         local lspconfig = require('lspconfig')

    --         lspconfig['lua_ls'].setup({ capabilities = capabilities })
    --     end
    -- },

    { "L3MON4D3/LuaSnip" },

    -- AI assistants
    {
        "supermaven-inc/supermaven-nvim",
        config = function()
            require("supermaven-nvim").setup({})
        end,
    },
    {
        "olimorris/codecompanion.nvim",
        config = true,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
        },
    },

    { "eandrju/cellular-automaton.nvim" },
    { "laytan/cloak.nvim" },
    { "kaarmu/typst.vim",               ft = "typst", lazy = false },

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
