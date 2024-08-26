---@type MappingsTable
local M = {}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },

    --  format with conform
    ["<leader>fm"] = {
      function()
        require("conform").format()
      end,
      "formatting",
    },
    ["<leader>cx"] = { ":%bd|e#<CR>", "close all other buffers" },
    ["<leader>ee"] = { "oif err != nil {<CR>}<Esc>Oreturn err;<Esc>", "insert go error handling"}
  },
  v = {
    [">"] = { ">gv", "indent"},
  },
}

-- telescope
M.telescope = {
  n = {
    ["<leader>fs"] = {
      function()
        require("telescope.builtin").lsp_dynamic_workspace_symbols()
      end,
      "Search workspace symbols",
    }
  }
}

-- more keybinds!

M.copilot = {
  i = {
    ["<C-l>"] = {
      function()
        vim.fn.feedkeys(vim.fn['copilot#Accept'](), '')
      end,
      "Copilot Accept",
      {replace_keycodes = true, nowait=true, silent=true, expr=true, noremap=true}
    }
  }
}

M.obsidian = {
  n = {
    ["<leader>op"] = {
      function()
        require("obsidian")
        vim.api.nvim_command(":ObsidianQuickSwitch")
      end,
      "Quick Open Obsidian",
    }
  }
}

return M
