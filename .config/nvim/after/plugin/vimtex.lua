-- Set remap to view the pdf file of the current tex file in the default pdf viewer

vim.g.vimtex_view_method = 'zathura'

-- Set remap to compile the current tex file
-- vim.api.nvim_set_keymap('n', '<leader>vc', ':VimtexCompile<CR>', { noremap = true, silent = true })

-- Set remap to view the pdf file of the current tex file
vim.api.nvim_set_keymap('n', '<leader>vp', ':VimtexView<CR>', { noremap = true, silent = true })
