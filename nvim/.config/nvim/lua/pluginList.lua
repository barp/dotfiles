local plugin_status = require("utils").load_config().plugin_status

local present, _ = pcall(require, "packerInit")
local packer

if present then
	packer = require("packer")
else
	return false
end

vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost pluginList.lua source <afile> | PackerSync
  augroup END
]])

local use = packer.use

return packer.startup(function()
	use({
		"wbthomason/packer.nvim",
		event = "VimEnter",
	})

	use({
		"jdhao/better-escape.vim",
		disable = not plugin_status.better_esc,
		event = "InsertEnter",
		config = function()
			require("plugins.others").escape()
		end,
	})

	use({
		"feline-nvim/feline.nvim",
		after = "nvim-base16.lua",
		config = function()
			require("plugins.statusline")
		end,
	})

	use({
		"akinsho/bufferline.nvim",
		after = "feline.nvim",
		disable = not plugin_status.nvim_bufferline,
		config = function()
			require("plugins.bufferline")
		end,
		setup = function()
			require("mappings").bufferline()
		end,
	})

	-- color related stuff
	use({
		"NvChad/nvim-base16.lua",
		after = "packer.nvim",
		config = function()
			require("theme")
		end,
	})

	use({
		"norcalli/nvim-colorizer.lua",
		disable = not plugin_status.nvim_colorizer,
		event = "BufRead",
		config = function()
			require("plugins.others").colorizer()
		end,
	})

	-- lsp stuff
	use({
		"nvim-treesitter/nvim-treesitter",
		event = "BufRead",
		config = function()
			require("plugins.treesitter")
		end,
	})

	use({
		"JoosepAlviste/nvim-ts-context-commentstring",
		after = "nvim-treesitter",
	})

	use({
		"rafamadriz/friendly-snippets",
	})

	use({
		"mfussenegger/nvim-dap",
		after = "telescope.nvim",
		config = function()
			require("plugins.dapconf")
		end,
		setup = function()
			require("mappings").dap()
		end,
	})

	use({
		"rcarriga/nvim-dap-ui",
		after = "nvim-dap",
		config = function()
			require("plugins.dapuiconf")
		end,
	})

	use({
		"theHamsta/nvim-dap-virtual-text",
		after = { "nvim-dap" },
		config = function()
			require("nvim-dap-virtual-text").setup()
		end,
	})

	use({
		"leoluz/nvim-dap-go",
		after = "nvim-dap",
		config = function()
			require("plugins.dapgo")
		end,
	})

	use({
		"L3MON4D3/LuaSnip",
		config = function()
			require("plugins.luasnip")
		end,
	})

	-- file managing , picker etc
	use({
		"kyazdani42/nvim-tree.lua",
		cmd = "NvimTreeToggle",
		config = function()
			require("plugins.nvimtree")
		end,
		setup = function()
			require("mappings").nvimtree()
		end,
	})

	use({
		"kyazdani42/nvim-web-devicons",
		after = "nvim-base16.lua",
		config = function()
			require("plugins.icons")
		end,
	})

	use({
		"nvim-lua/plenary.nvim",
	})
	use({
		"nvim-lua/popup.nvim",
		after = "plenary.nvim",
	})

	use({
		"liuchengxu/vista.vim",
		config = function()
			require("plugins.vista")
		end,
	})

	use({
		"nvim-telescope/telescope.nvim",
		after = "plenary.nvim",
		requires = {
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				run = "make",
			},
			{
				"nvim-telescope/telescope-media-files.nvim",
				disable = not plugin_status.telescope_media,
				setup = function()
					require("mappings").telescope_media()
				end,
			},
			{
				"sudormrfbin/cheatsheet.nvim",
				disable = not plugin_status.cheatsheet,
				event = "VimEnter",
				after = "telescope.nvim",
				config = function()
					require("plugins.chadsheet")
				end,
				setup = function()
					require("mappings").chadsheet()
				end,
			},
		},
		config = function()
			require("plugins.telescope")
		end,
		setup = function()
			require("mappings").telescope()
		end,
	})

	use({
		"mhinz/vim-startify",
		run = "mkdir -p $HOME/.local/share/nvim/session/",
		requires = {
			"itchyny/vim-gitbranch",
		},
		config = function()
			require("plugins.startify")
		end,
	})

	-- git stuff
	use({
		"lewis6991/gitsigns.nvim",
		disable = not plugin_status.gitsigns,
		after = "plenary.nvim",
		config = function()
			require("plugins.gitsigns")
		end,
	})

	use({
		"andymass/vim-matchup",
		disable = not plugin_status.vim_matchup,
		event = "CursorMoved",
	})

	use({
		"terrortylor/nvim-comment",
		disable = not plugin_status.nvim_comment,
		cmd = "CommentToggle",
		config = function()
			require("plugins.others").comment()
		end,
		setup = function()
			require("mappings").comment_nvim()
		end,
	})

	-- load autosave only if its globally enabled
	use({
		disable = not plugin_status.autosave_nvim,
		"Pocco81/AutoSave.nvim",
		config = function()
			require("plugins.autosave")
		end,
		cond = function()
			return vim.g.auto_save == true
		end,
	})

	-- smooth scroll
	use({
		"karb94/neoscroll.nvim",
		disable = not plugin_status.neoscroll_nvim,
		event = "WinScrolled",
		config = function()
			require("plugins.others").neoscroll()
		end,
	})

	use({
		"lukas-reineke/indent-blankline.nvim",
		disable = not plugin_status.blankline,
		event = "BufRead",
		setup = function()
			require("plugins.others").blankline()
		end,
	})

	use({
		"tpope/vim-fugitive",
		disable = not plugin_status.vim_fugitive,
		cmd = {
			"Git",
		},
		setup = function()
			require("mappings").fugitive()
		end,
	})

	use({
		"akinsho/toggleterm.nvim",
		run = "pip3 install neovim-remote",
		config = function()
			require("plugins.term")
		end,
	})

	use({
		"rcarriga/nvim-notify",
		config = function()
			require("plugins.notify")
		end,
	})

	use({
		"phaazon/hop.nvim",
		config = function()
			require("hop").setup()
		end,
		setup = function()
			require("mappings").hop()
		end,
	})

	use({
		"neovim/nvim-lspconfig",
		requires = {
			"williamboman/nvim-lsp-installer",
			"ray-x/lsp_signature.nvim",
			"MunifTanjim/nui.nvim",
		},
		config = function()
			require("plugins.lspconfig")
		end,
	})

	use({
		"jose-elias-alvarez/null-ls.nvim",
		config = function()
			require("plugins.nullls")
		end,
	})

	-- cmp stuff
	use({
		"hrsh7th/nvim-cmp",
		after = {
			"nvim-lspconfig",
			"LuaSnip",
			"plenary.nvim",
		},
		requires = {
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"saadparwaiz1/cmp_luasnip",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lua",
		},
		config = function()
			require("plugins.nvimcmp")
		end,
		setup = function()
			require("mappings").lsp()
		end,
	})

	use({
		"windwp/nvim-autopairs",
		after = "nvim-cmp",
		config = function()
			require("plugins.autopairs")
		end,
	})

	use({
		"iamcco/markdown-preview.nvim",
		run = "cd app && yarn install",
		config = function()
			vim.g.mkdp_open_ip = vim.fn.hostname()
			vim.g.mkdp_echo_preview_url = 1
		end,
	})

	use({
		"folke/which-key.nvim",
		config = function()
			require("which-key").setup({
				triggers = { "<leader>" },
			})
		end,
	})
end)
