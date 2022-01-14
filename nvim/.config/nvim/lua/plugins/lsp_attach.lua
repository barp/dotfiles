local M = {}

M.on_attach = function(client, bufnr)
	vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

	local opts = { noremap = true, silent = true }

	local function buf_set_keymap(...)
		vim.api.nvim_buf_set_keymap(bufnr, ...)
	end

	-- Mappings.

	buf_set_keymap("n", "gD", "<Cmd>lua vim.lsp.buf.declaration()<CR>", opts)
	buf_set_keymap("n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", opts)
	buf_set_keymap("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
	buf_set_keymap("n", "<space>wa", "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", opts)
	buf_set_keymap("n", "<space>wr", "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", opts)
	buf_set_keymap("n", "<space>wl", "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>", opts)
	buf_set_keymap("n", "<space>e", "<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>", opts)
	buf_set_keymap("n", "[g", "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>", opts)
	buf_set_keymap("n", "]g", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>", opts)
	buf_set_keymap("n", "<space>q", "<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>", opts)

	buf_set_keymap("n", "<leader>rn", "<cmd>lua require('lsprenameui').lsp_rename()<CR>", opts)

	buf_set_keymap(
		"n",
		"<leader>D",
		":lua require'telescope.builtin'.lsp_type_definitions(require'telescope.themes'.get_cursor({path_display = {'shorten'}, layout_config={width=150}}))<CR>",
		opts
	)

	buf_set_keymap(
		"n",
		"gd",
		":lua require'telescope.builtin'.lsp_definitions(require'telescope.themes'.get_cursor({path_display = {'shorten'}, layout_config={width=150}}))<CR>",
		opts
	)
	buf_set_keymap(
		"n",
		"gi",
		":lua require'telescope.builtin'.lsp_implementations(require'telescope.themes'.get_cursor({path_display = {'shorten'}, layout_config={width=150}}))<CR>",
		opts
	)
	buf_set_keymap(
		"n",
		"gr",
		":lua require'telescope.builtin'.lsp_references(require'telescope.themes'.get_cursor({path_display = {'shorten'}, layout_config={width=150}}))<CR>",
		opts
	)
	buf_set_keymap("n", "<leader>ca", ":Telescope lsp_code_actions theme=get_cursor<CR>", opts)
	buf_set_keymap("v", "<leader>ca", ":Telescope lsp_range_code_actions theme=get_cursor<CR>", opts)

	-- Set some keybinds conditional on server capabilities
	if client.resolved_capabilities.document_formatting then
		vim.cmd(
			[[
     augroup LspFormatting
        autocmd! * <buffer>
        autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_seq_sync()
     augroup END
     ]],
			false
		)
	elseif client.resolved_capabilities.document_range_formatting then
		buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.range_formatting()<CR>", opts)
	end

	if client.resolved_capabilities.document_highlight then
		vim.api.nvim_exec(
			[[
     augroup lsp_document_highlight
        autocmd! * <buffer>
        autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
     augroup END
     ]],
			false
		)
	end
end

return M
