local autocmd = vim.api.nvim_create_autocmd

-- Auto resize panes when resizing nvim window
-- autocmd("VimResized", {
--   pattern = "*",
--   command = "tabdo wincmd =",
-- })

vim.filetype.add({ extension = { templ = "templ" }})

autocmd({"BufEnter"}, {
  pattern = "*.go",
  command = "setlocal tabstop=4 shiftwidth=4 noexpandtab",
})

autocmd({"BufWritePost"}, {
  pattern = "*.go",
  callback = function()
    vim.cmd("silent! !golines -w %")
    vim.cmd("silent! !gofumpt -w %")
  end
})

vim.opt.conceallevel = 1
