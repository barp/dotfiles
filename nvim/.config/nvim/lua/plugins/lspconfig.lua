local lspsignature = require("lsp_signature")
local on_attach = require("plugins.lsp_attach").on_attach
local present2, lspinstall = pcall(require, "nvim-lsp-installer")
if not present2 then
	return
end

lspsignature.setup({
	bind = true,
	handler_opts = {
		border = "rounded",
	},
	floating_window_above_cur_line = false,
})

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

lspinstall.on_server_ready(function(server)
	local opts = {
		capabilities = capabilities,
		on_attach = on_attach,
	}
	local lang = server.languages[1]
	if lang == "lua" then
		opts = vim.tbl_deep_extend("force", {
			root_dir = vim.loop.cwd,
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
					},
					workspace = {
						library = {
							[vim.fn.expand("$VIMRUNTIME/lua")] = true,
							[vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
							[vim.fn.stdpath("config") .. "/lua"] = true,
						},
						maxPreload = 100000,
						preloadFileSize = 10000,
					},
					telemetry = {
						enable = false,
					},
				},
			},
		}, opts)
	elseif server.name == "jsonls" or server.name == "yamlls" then
		local jsonls_opts = require("jsonls")[server.name]
		opts = vim.tbl_deep_extend("force", jsonls_opts, opts)
	elseif server.name == "pyright" then
		opts = vim.tbl_deep_extend("force", {
			settings = {
				python = {
					analysis = {
						typeCheckingMode = "off",
					},
				},
			},
		}, opts)
	end

	server:setup(opts)
end)

-- Automatically reload after `:LspInstall <server>` so we don't have to restart neovim
lspinstall.post_install_hook = function()
	-- setup_servers() -- reload installed servers
	vim.cmd("bufdo e")
end

-- replace the default lsp diagnostic symbols
local function lspSymbol(name, icon)
	vim.fn.sign_define("DiagnosticSign" .. name, { texthl = "DiagnosticSign" .. name, text = icon, numhl = "" })
end
lspSymbol("Error", "")
lspSymbol("Warn", "")
lspSymbol("Info", "")
lspSymbol("Hint", "")

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
	virtual_text = {
		prefix = "",
		spacing = 0,
	},
	signs = true,
	underline = true,
	-- set this to true if you want diagnostics to show in insert mode
	update_in_insert = false,
})

-- suppress error messages from lang servers
vim.notify = function(msg, log_level, _opts)
	if msg:match("exit code") then
		return
	end
	if log_level == vim.log.levels.ERROR then
		vim.api.nvim_err_writeln(msg)
	else
		vim.api.nvim_echo({ { msg } }, true, {})
	end
end
