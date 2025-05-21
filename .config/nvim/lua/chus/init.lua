require("chus.set")
require("chus.remap")

local augroup = vim.api.nvim_create_augroup
local ChusGroup = augroup("Chus", {})

local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup("HighlightYank", {})

function R(name)
    require("plenary.reload").reload_module(name)
end

autocmd("TextYankPost", {
    group = yank_group,
    pattern = "*",
    callback = function()
        vim.highlight.on_yank({
            higroup = "IncSearch",
            timeout = 40,
        })
    end,
})

autocmd({ "BufWritePre" }, {
    group = ChusGroup,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

autocmd("FileType", {
    -- All JS/TS files
    pattern = "javascript,typescript,javascriptreact,typescriptreact",
    command = [[setlocal tabstop=2 shiftwidth=2]],
})

vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25

require("chus.plugins")

vim.cmd("colorscheme jb")
vim.cmd("set background=light")
