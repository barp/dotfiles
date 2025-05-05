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
    ["<leader>ee"] = { "oif err != nil {<CR>}<Esc>Oreturn err;<Esc>", "insert go error handling"},
    ["<leader>oc"] = {":CodeCompanionActions<CR>", "open code companion actions"}
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

M.llm = {
  v = {
    ["<leader>ta"] = {
      function()
        local system_prompt =
        'You should replace the code that you are sent, only following the comments. Do not talk at all. Only output valid code. Do not provide any backticks that surround the code. Never ever output backticks like this ```. Any comment that is asking you for something should be removed after you satisfy them. Other comments should left alone. Do not output backticks'
        local dingllm = require 'dingllm'
        dingllm.invoke_llm_and_stream_into_editor({
          url = 'https://api.anthropic.com/v1/messages',
          model = 'claude-3-5-sonnet-20241022',
          api_key_name = 'ANTHROPIC_API_KEY',
          system_prompt = system_prompt,
          replace = true,
        }, dingllm.make_anthropic_spec_curl_args, dingllm.handle_anthropic_spec_data)
      end,
      "LLM Anthropic replace",
    }
  },
  n = {
    ["<leader>ta"] = {
      function()
        local system_prompt =
        'You should replace the code that you are sent, only following the comments. Do not talk at all. Only output valid code. Do not provide any backticks that surround the code. Never ever output backticks like this ```. Any comment that is asking you for something should be removed after you satisfy them. Other comments should left alone. Do not output backticks'
        local dingllm = require('dingllm')
        print("running")
        dingllm.invoke_llm_and_stream_into_editor({
          url = 'https://api.anthropic.com/v1/messages',
          model = 'claude-3-5-sonnet-20241022',
          api_key_name = 'ANTHROPIC_API_KEY',
          system_prompt = system_prompt,
          replace = true,
        }, dingllm.make_anthropic_spec_curl_args, dingllm.handle_anthropic_spec_data)
      end,
      "LLM Anthropic replace",
    }
  }
}

return M
