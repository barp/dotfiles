local overrides = require("custom.configs.overrides")

---@type NvPluginSpec[]
local plugins = {

  -- Override plugin definition options
  --
  {
  "ray-x/go.nvim",
  dependencies = {  -- optional packages
    "ray-x/guihua.lua",
    "neovim/nvim-lspconfig",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("go").setup()
  end,
  event = {"CmdlineEnter"},
  ft = {"go", 'gomod'},
  build = ':lua require("go.install").update_all_sync()' -- if you need to install/update all binaries
},
  {
    "elentok/format-on-save.nvim",
    config = function()
      require "custom.configs.format_on_save"
    end,
    lazy = false,
  },
  {
    "epwalsh/obsidian.nvim",
    version = "*",  -- recommended, use latest release instead of latest commit
    ft = "markdown",
    dependencies = {
      -- Required.
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
    },
    opts = overrides.obsidian,
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end, -- Override to setup mason-lspconfig
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    ---@module 'render-markdown'
    config = function()
      require("render-markdown").setup({
        file_types = { 'markdown', 'vimwiki', 'codecompanion' }
      })
    end,
    ft = {'markdown', 'vimwiki', 'codecompanion'},
    ---@type render.md.UserConfig
    opts = {},
},
  {
    "olimorris/codecompanion.nvim",
    config = function()
      require("codecompanion").setup({
        strategies = {
          chat = {
            adapter = "gemini",
          },
          inline = {
            adapter = "gemini",
          },
        },
      })
    end,
    init = function ()
      require("custom.configs.fidget-spinner"):init()
    end,
    opts = {},
    dependencies = {
      "j-hui/fidget.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    lazy = false,
  },

  {
    "github/copilot.vim",
    lazy = false,
    config = function()
      -- Mapping tab is already used by NvChad
      vim.g.copilot_no_tab_map = true;
      vim.g.copilot_assume_mapped = true;
      vim.g.copilot_tab_fallback = "";
      -- The mapping is set to other key, see custom/lua/mappings
      -- or run <leader>ch to see copilot mapping sections
    end
  },

  -- override plugin configs
  {
    "williamboman/mason.nvim",
    opts = overrides.mason
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = overrides.treesitter,
  },

  {
    "nvim-tree/nvim-tree.lua",
    opts = overrides.nvimtree,
  },

  -- Install a plugin
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    config = function()
      require("better_escape").setup()
    end,
  },

  {
    "stevearc/conform.nvim",
    --  for users those who want auto-save conform + lazyloading!
    -- event = "BufWritePre"
    config = function()
      require "custom.configs.conform"
    end,
  },
  -- { 'augmentcode/augment.vim', lazy=false },
  {
    'mfussenegger/nvim-dap',
    dependencies={
      'leoluz/nvim-dap-go',
      'mfussenegger/nvim-dap-python',
      'rcarriga/nvim-dap-ui',
      'theHamsta/nvim-dap-virtual-text',
      'nvim-neotest/nvim-nio',
      'williamboman/mason.nvim'
    },
    lazy=false,
    config = function()
      local dap = require "dap"
      local ui = require "dapui"

      require("dapui").setup({
        element_mappings = {
          stacks = {
            open = "<CR>",
            expand = "o",
          }
        }
      })
      require("dap-python").setup("python3")
      require('dap-go').setup()

      require("nvim-dap-virtual-text").setup {
        display_callback = function(variable)
          if #variable.value > 15 then
            return " " .. string.sub(variable.value, 1, 15) .. "... "
          end

          return " " .. variable.value
        end
      }

      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint)
      vim.keymap.set("n", "<leader>dt", ":lua require('dapui').toggle({})<CR>", {silent=true})
      vim.keymap.set("n", "<leader>dg", dap.run_to_cursor)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = {"python"},
        callback = function(ev)
          vim.api.nvim_buf_set_keymap(0, "n", "<leader>dn", ":lua require('dap-python').test_method({config = { justMyCode = false }})<CR>", {silent=true})
        end
      })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = {"go"},
        callback = function(ev)
          vim.api.nvim_buf_set_keymap(0, "n", "<leader>dn", ":lua require('dap-go').debug_test()<CR>", {silent=true})
        end
      })

      vim.keymap.set("n", "<F1>", dap.continue)
      vim.keymap.set("n", "<F2>", dap.step_into)
      vim.keymap.set("n", "<F3>", dap.step_over)
      vim.keymap.set("n", "<F4>", dap.step_out)
      vim.keymap.set("n", "<F5>", dap.step_back)
      vim.keymap.set("n", "<F12>", dap.restart)

      dap.listeners.before.attach.dapui_config = function()
        ui.open()
      end

      dap.listeners.before.launch.dapui_config = function()
        ui.open()
      end

      dap.listeners.before.event_terminated.dapui_config = function()
        ui.close()
      end

      dap.listeners.before.event_exited.dapui_config = function()
        ui.close()
      end
    end,
  },
  {
    "yorickpeterse/nvim-window",
    keys = {
      { "<leader>wj", "<cmd>lua require('nvim-window').pick()<cr>", desc = "nvim-window: Jump to window" },
    },
    config = true,
  }
}

return plugins
