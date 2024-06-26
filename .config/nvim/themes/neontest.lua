-- Colorscheme generated by https://github.com/arcticlimer/djanho
vim.cmd[[highlight clear]]

local highlight = function(group, bg, fg, attr)
    fg = fg and 'guifg=' .. fg or ''
    bg = bg and 'guibg=' .. bg or ''
    attr = attr and 'gui=' .. attr or ''

    vim.api.nvim_command('highlight ' .. group .. ' '.. fg .. ' ' .. bg .. ' '.. attr)
end

local link = function(target, group)
    vim.api.nvim_command('highlight! link ' .. target .. ' '.. group)
end

local Color2 = '#FF5370'
local Color3 = '#21ff75'
local Color1 = '#ee5cfd'
local Color9 = '#fff'
local Color5 = '#1b1b1b'
local Color4 = '#00ffff'
local Color0 = '#dfdfdf'
local Color6 = '#222222'
local Color10 = '#202020'
local Color7 = '#eeffff'
local Color8 = '#0f9797'

highlight('Comment', nil, Color0, 'italic')
highlight('Identifier', nil, Color1, nil)
highlight('Error', nil, Color2, nil)
highlight('Keyword', nil, Color3, nil)
highlight('Conditional', nil, Color3, nil)
highlight('Repeat', nil, Color3, nil)
highlight('Function', nil, Color4, nil)
highlight('Number', nil, Color4, nil)
highlight('TSCharacter', nil, Color4, nil)
highlight('String', nil, Color1, nil)
highlight('StatusLine', Color3, Color5, nil)
highlight('WildMenu', Color6, Color7, nil)
highlight('Pmenu', Color6, Color7, nil)
highlight('PmenuSel', Color7, Color1, nil)
highlight('PmenuThumb', Color6, Color7, nil)
highlight('Normal', Color6, Color7, nil)
highlight('Visual', Color8, nil, nil)
highlight('CursorLine', Color8, nil, nil)
highlight('ColorColumn', Color8, nil, nil)
highlight('SignColumn', Color6, nil, nil)
highlight('LineNr', nil, Color4, nil)
highlight('TabLine', Color10, Color9, nil)
highlight('TabLineSel', Color9, Color1, nil)
highlight('TabLineFill', Color10, Color9, nil)
highlight('TSPunctDelimiter', nil, Color7, nil)

link('CursorLineNr', 'Identifier')
link('TSConstant', 'Constant')
link('TSNamespace', 'TSType')
link('Conditional', 'Operator')
link('Whitespace', 'Comment')
link('TSType', 'Type')
link('TSLabel', 'Type')
link('TSPunctBracket', 'MyTag')
link('TSFloat', 'Number')
link('TSParameter', 'Constant')
link('Macro', 'Function')
link('TSPunctSpecial', 'TSPunctDelimiter')
link('Operator', 'Keyword')
link('TSProperty', 'TSField')
link('TSOperator', 'Operator')
link('TSFuncMacro', 'Macro')
link('TelescopeNormal', 'Normal')
link('Repeat', 'Conditional')
link('TSTagDelimiter', 'Type')
link('TSRepeat', 'Repeat')
link('Folded', 'Comment')
link('TSConstBuiltin', 'TSVariableBuiltin')
link('TSKeyword', 'Keyword')
link('TSString', 'String')
link('TSNumber', 'Number')
link('TSConditional', 'Conditional')
link('TSTag', 'MyTag')
link('NonText', 'Comment')
link('TSField', 'Constant')
link('TSFunction', 'Function')
link('TSComment', 'Comment')
link('TSParameterReference', 'TSParameter')

