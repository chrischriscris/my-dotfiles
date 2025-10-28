require("codecompanion").setup({
	adapters = {
		acp = {
			claude_code = function()
				return require("codecompanion.adapters").extend("claude_code", {
					env = {
						CLAUDE_CODE_OAUTH_TOKEN = "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",
					},
				})
			end,
		},
	},
	strategies = {
		chat = {
			adapter = "claude_code",
		},
	},
})
