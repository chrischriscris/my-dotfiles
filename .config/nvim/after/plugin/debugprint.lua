local js_like = {
    left = 'console.info("',
    right = '")',
    mid_var = '", ',
    right_var = ")",
}

require("debugprint").setup({
    keymaps = {
        normal = {
            plain_below = "g?p",
            plain_above = "g?P",
            variable_below = "g?v",
            variable_above = "g?V",
            variable_below_alwaysprompt = "",
            variable_above_alwaysprompt = "",
            textobj_below = "g?o",
            textobj_above = "g?O",
            toggle_comment_debug_prints = "",
            delete_debug_prints = "",
        },
        insert = {
            plain = "<C-G>p",
            variable = "<C-G>v",
        },
        visual = {
            variable_below = "g?v",
            variable_above = "g?V",
        },
    },
    commands = {
        toggle_comment_debug_prints = "ToggleCommentDebugPrints",
        delete_debug_prints = "DeleteDebugPrints",
        reset_debug_prints_counter = "ResetDebugPrintsCounter",
    },
    filetypes = {
        ["javascript"] = js_like,
        ["javascriptreact"] = js_like,
        ["typescript"] = js_like,
        ["typescriptreact"] = js_like,
    },
})
