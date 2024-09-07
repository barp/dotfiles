local format_on_save = require("format-on-save")
local formatters = require("format-on-save.formatters")

format_on_save.setup({
  formatter_by_ft = {
    html = formatters.lsp,
    svelte = formatters.lsp,
    typescript = formatters.prettierd,
    typescriptreact = formatters.prettierd,
    go = {
      formatters.shell({
        cmd = {"golines", "-w", "%"},
        tempfile = function()
          return vim.fn.expand("%") .. '.formatter-temp'
        end
      }),
      formatters.shell({ cmd = { "gofmt" } }),
      formatters.shell({ cmd = { "gofumpt" } }),
    },
  },
  run_with_sh = false,
})
