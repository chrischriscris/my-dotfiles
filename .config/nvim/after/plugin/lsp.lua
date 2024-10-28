local lsp = require("lsp-zero")

lsp.preset("recommended")

local cmp = require("cmp")
local cmp_select = { behavior = cmp.SelectBehavior.Select }
local cmp_map = cmp.mapping

cmp.setup({
	window = {
		completion = cmp.config.window.bordered(),
		documentation = cmp.config.window.bordered(),
	},
	mapping = cmp_map.preset.insert({
		["<C-p>"] = cmp_map.select_prev_item(cmp_select),
		["<C-n>"] = cmp_map.select_next_item(cmp_select),
		["<C-y>"] = cmp_map.confirm({ select = true }),
		["<C-Space>"] = cmp_map.complete(),
		["<Tab>"] = nil,
		["<S-Tab>"] = nil,
	}),
	sources = {
		{ name = "nvim_lsp" },
		{ name = "mason" },
		{ name = "null" },
	},
})

lsp.set_preferences({
	suggest_lsp_servers = false,
	sign_icons = {
		error = "E",
		warn = "W",
		hint = "H",
		info = "I",
	},
})

lsp.on_attach(function(client, bufnr)
	local opts = { buffer = bufnr, remap = false }

	vim.keymap.set("n", "gd", function()
		vim.lsp.buf.definition()
	end, opts)
	vim.keymap.set("n", "K", function()
		vim.lsp.buf.hover()
	end, opts)
	vim.keymap.set("n", "<leader>vws", function()
		vim.lsp.buf.workspace_symbol()
	end, opts)
	vim.keymap.set("n", "<leader>vd", function()
		vim.diagnostic.open_float()
	end, opts)
	vim.keymap.set("n", "[d", function()
		vim.diagnostic.goto_next()
	end, opts)
	vim.keymap.set("n", "]d", function()
		vim.diagnostic.goto_prev()
	end, opts)
	vim.keymap.set("n", "<leader>vca", function()
		vim.lsp.buf.code_action()
	end, opts)
	vim.keymap.set("n", "<leader>vrr", function()
		vim.lsp.buf.references()
	end, opts)
	vim.keymap.set("n", "<leader>vrn", function()
		vim.lsp.buf.rename()
	end, opts)
	vim.keymap.set("i", "<C-h>", function()
		vim.lsp.buf.signature_help()
	end, opts)
end)

-- Mason configuration
require("mason").setup({})
require("mason-lspconfig").setup({
	ensure_installed = { "ts_ls", "rust_analyzer", "gopls" },
	handlers = { lsp.default_setup },
})

lsp.setup()

vim.diagnostic.config({
	virtual_text = true,
})

-- Null LS configuration
local null_ls = require("null-ls")

local formatting = null_ls.builtins.formatting
-- local diagnostics = null_ls.builtins.diagnostics
local completion = null_ls.builtins.completion

null_ls.setup({
	sources = {
		formatting.stylua,
		formatting.prettier,
		formatting.typstfmt,

		completion.spell,
	},
})

local lspconfig = require("lspconfig")

-- Python's Ruff configuration
-- Configure better later, I don't have time now
lspconfig.ruff.setup({})

lspconfig.tinymist.setup{
    -- vvv This is to mitigate a neovim bug, review later to see if it's fixed
    -- https://github.com/Myriad-Dreamin/tinymist/issues/638
    offset_encoding = "utf-8",
    settings = {
        formatterMode = "typstyle",
        exportPdf = "onSave",
    },
}
