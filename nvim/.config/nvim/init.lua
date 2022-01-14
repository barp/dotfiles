local au = require("au")

local chad_modules = {
	"options",
	"mappings",
}

for i = 1, #chad_modules, 1 do
	if not pcall(require, chad_modules[i]) then
		error("Error loading " .. chad_modules[i] .. "\n")
	end
end

require("mappings").misc()
-- vim.cmd("source ~/.vim_runtime/my_configs.vim")
vim.g.python_recommended_style = 0

au("FileType", {
	"python",
	"setlocal shiftwidth=2 softtabstop=2 tabstop=2 expandtab",
})

vim.opt.relativenumber = true
