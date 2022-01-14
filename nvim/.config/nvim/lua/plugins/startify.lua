local au = require('au')

vim.g.startify_lists = {
    {type = "dir", header = {"Recently edited files in "..vim.fn.getcwd()..":"}},
    {type = "bookmarks", header = {"Bookmarks"}}
}

vim.g.startify_bookmarks = {
    {v = '~/projects/v2k/v2k-core'},
    {c = '~/.vim_runtime/my_configs.vim'},
    {p = '~/.vim_runtime/nvim_config/lua/pluginList.lua'},
    {z = '~/.zshrc'},
}

vim.g.startify_change_to_vcs_root = 1
vim.g.startify_change_to_dir = 0

function GetUniqueSessionName()
    local path = vim.fn.fnamemodify(vim.fn.getcwd(), ':~:t')
    path = path == '' and 'no-project' or path
    local branch = vim.fn["gitbranch#name"]()
    branch = branch == '' and '' or '-'..branch
    return string.gsub(path .. branch, '/', '-')
end

au('User', {
    'StartifyReady',
    "execute 'SLoad "..GetUniqueSessionName().."'"
})

au('VimLeavePre', {
    '*',
    "silent execute 'SSave! "..GetUniqueSessionName().."'"
})
