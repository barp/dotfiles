local present, ts_config = pcall(require, "nvim-treesitter.configs")
if not present then
	return
end

ts_config.setup({
	context_commentstring = {
		enable = true,
		enable_autocmd = false,
	},
	ensure_installed = {
		"bash",
		"lua",
		"go",
		"python",
		"yaml",
		"vim",
		"json",
		"make",
		"comment",
		"dart",
		"toml",
	},
	highlight = {
		enable = true,
		use_languagetree = true,
	},
})
