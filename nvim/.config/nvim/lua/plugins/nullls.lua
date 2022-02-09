local null_ls = require("null-ls")

local formatting = null_ls.builtins.formatting
local diagnostics = null_ls.builtins.diagnostics
local codeactions = null_ls.builtins.code_actions

null_ls.setup({
	debug = false,
	sources = {
		formatting.stylua,
		formatting.goimports,
		formatting.shfmt,
		formatting.yapf,
		diagnostics.shellcheck,
		codeactions.shellcheck,
	},
	on_attach = require("plugins.lsp_attach").on_attach,
})
