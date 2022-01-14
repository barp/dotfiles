local api = vim.api
local dap = require("dap")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local M = {}

-- support debugpy custom multiprocess event
local sessions = {}

M.widgets = {}
M.widgets.sessions = {
	refresh_listener = "event_initialized",
	new_buf = function()
		local buf = api.nvim_create_buf(false, true)
		api.nvim_buf_set_option(buf, "buftype", "nofile")
		api.nvim_buf_set_keymap(buf, "n", "<CR>", "<Cmd>lua require('dap.ui').trigger_actions()<CR>", {})
		api.nvim_buf_set_keymap(buf, "n", "<2-LeftMouse>", "<Cmd>lua require('dap.ui').trigger_actions()<CR>", {})
	end,
	render = function(view)
		local layer = view.layer()
		local render_session = function(session)
			local suffix
			if session.current_frame then
				suffix = "Stopped at line " .. session.current_frame.line
			elseif session.stopped_thread_id then
				suffix = "Stopped"
			else
				suffix = "Running"
			end

			local prefix = session == dap.session() and "→ " or "  "

			return prefix .. (session.config.name or "No name") .. " (" .. suffix .. ")"
		end
		local context = {}
		context.actions = {
			{
				label = "Activate session",
				fn = function(_, session)
					if session then
						dap.set_session(session)
						if vim.bo.bufhidden == "wipe" then
							view.close()
						else
							view.refresh()
						end
					end
				end,
			},
		}
		layer.render(vim.tbl_keys(sessions), render_session, context)
	end,
}

-- Activate widget with :lua require('dap.ui.widgets').sidebar(require('plugins.dapconf').widgets.sessions).open()

dap.listeners.after["event_debugpyAttach"]["dap-python"] = function(_, config)
	print(vim.inspect(config))
	local on_connect = function(_) end
	local session = require("dap.session"):connect(
		{ host = config.connect.host, port = config.connect.port },
		{},
		on_connect
	)
	-- Dirty fix, we need to wait for some time after using connect in order to initialize the session
	-- Maybe using the on_connect function will be better
	vim.defer_fn(function()
		session:initialize(config)
		dap.set_session(session)
		sessions[session] = true
	end, 500)
end

dap.listeners.after.event_initialized["dap-python"] = function(session)
	sessions[session] = true
end

local remove_session = function(session)
	sessions[session] = nil
end

dap.listeners.after.event_exited["dap-python"] = remove_session
dap.listeners.after.event_terminated["dap-python"] = remove_session
-- end python support
-- start sonic tests support
local select_suite = function(cb, opts)
	opts = opts or {}
	pickers.new(opts, {
		prompt_title = "Suite",
		finder = finders.new_oneshot_job({ "find", "./test/suites/", "-name", "*.yaml", "-printf", "%f\n" }, {
			entry_maker = function(entry)
				return {
					value = "./test/suites/" .. entry,
					display = entry,
					ordinal = entry,
					suite_path = "suites/" .. entry,
				}
			end,
		}),
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, _)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				cb(selection)
			end)
			return true
		end,
		previewer = conf.file_previewer(opts),
	}):find()
end

local select_test = function(cb, suite, opts)
	opts = opts or {}
	local command = { "python3", "-m", "sonic", "by-suite", suite, "--collect-only" }
	pickers.new(opts, {
		prompt_title = "Test",
		finder = finders.new_oneshot_job(command, {
			cwd = "./test/",
			entry_maker = function(entry)
				return {
					value = entry,
					display = entry,
					ordinal = entry,
				}
			end,
		}),
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				cb(selection)
			end)
			return true
		end,
	}):find()
end

local trigger_test = function(suite, name)
	dap.run({
		name = name,
		type = "python",
		request = "launch",
		module = "sonic",
		cwd = "${workspaceFolder}/test",
		args = { "by-suite", "--imagever", vim.env.IMAGEVER, "--current-cluster", "--skip-init", suite, name },
		console = "externalTerminal",
	})
end

M.trigger_sonic = function()
	select_suite(function(entry)
		local suite_path = tostring(entry.suite_path)
		vim.schedule(function()
			select_test(function(test)
				trigger_test(suite_path, tostring(test.value))
			end, suite_path)
		end)
	end)
end

-- end sonic test support

dap.adapters.go = function(callback, config)
	local stdout = vim.loop.new_pipe(false)
	local handle
	local pid_or_err
	local port = 38697
	local opts = {
		stdio = { nil, stdout },
		args = { "dap", "-l", "127.0.0.1:" .. port },
		detached = true,
	}
	handle, pid_or_err = vim.loop.spawn("dlv", opts, function(code)
		stdout:close()
		handle:close()
		if code ~= 0 then
			print("dlv exited with code", code)
		end
	end)
	assert(handle, "Error running dlv: " .. tostring(pid_or_err))
	stdout:read_start(function(err, chunk)
		assert(not err, err)
		if chunk then
			vim.schedule(function()
				require("dap.repl").append(chunk)
			end)
		end
	end)
	-- Wait for delve to start
	vim.defer_fn(function()
		callback({ type = "server", host = "127.0.0.1", port = port })
	end, 100)
end

dap.configurations.go = {
	{
		type = "go",
		name = "Debug",
		request = "launch",
		program = "${file}",
	},
	{
		type = "go",
		name = "Debug test", -- configuration for debugging test files
		request = "launch",
		mode = "test",
		program = "${file}",
	},
	-- works with go.mod packages and sub packages
	{
		type = "go",
		name = "Debug test (go.mod)",
		request = "launch",
		mode = "test",
		program = "./${relativeFileDirname}",
	},
}

if vim.env.TMUX then
	dap.defaults.python.external_terminal = {
		command = "tmux",
		args = { "split-window", "-h" },
	}
else
	dap.defaults.python.external_terminal = {
		command = "alacritty",
		args = { "-e" },
	}
end

dap.adapters.python = {
	type = "executable",
	command = "python3",
	args = { "-m", "debugpy.adapter" },
}

dap.configurations.python = {
	{
		type = "python",
		request = "launch",
		name = "Start sonic test",

		-- Sonic specific config
		module = "sonic",
		cwd = "${workspaceFolder}/test",
		args = function()
			return {
				"on-demand",
				"--current-cluster",
				"--skip-init",
				vim.fn.input("Please supply the name of the function: "),
				"${file}",
			}
		end,
		subProcess = true,
	},
}

return M
