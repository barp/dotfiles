local au = require('au')

-- Configure vista outline panel
vim.api.nvim_set_keymap('n', '<leader><leader>v', ':Vista!!<CR>', {noremap = true, silent = true})

-- Make vista load for statusline
au("VimEnter", {
  "*",
  "call vista#RunForNearestMethodOrFunction()"
})


-- Close vista when leaving vista window
vim.g.vista_close_on_jump = 1

vim.g["vista#renderer#icons"] = {
  members = "",
  classes = "",
}
