local add_to_luapath = function(dir)
	package.path = table.concat({
		dir .. "/?.lua",
		dir .. "/?/init.lua",
		package.path,
	}, ";")
end

-- add project dir first (lua source directory)
add_to_luapath("./lua")

-- if in github actions, add a clone of plenary to the package path
if os.getenv("GITHUB_ACTIONS") == "true" then
	local plenary_path = vim.fn.expand("$GITHUB_WORKSPACE/../plenary.nvim")
	if vim.fn.isdirectory(plenary_path) == 0 then
		vim.fn.system({
			"git",
			"clone",
			"https://github.com/nvim-lua/plenary.nvim",
			plenary_path,
		})
	end

	package.path = table.concat({
		plenary_path .. "/lua/?.lua",
		plenary_path .. "/lua/?/init.lua",
		package.path,
	}, ";")

	local ascii_ui_path = vim.fn.expand("$GITHUB_WORKSPACE/../ascii-ui.nvim")
	if vim.fn.isdirectory(ascii_ui_path) == 0 then
		vim.fn.system({
			"git",
			"clone",
			"https://github.com/rcasia/ascii-ui.nvim",
			ascii_ui_path,
		})
	end

	add_to_luapath(ascii_ui_path .. "/lua")
else
	-- local development: use .tests directory
	local plenary_path = "./.tests/site/pack/deps/start/plenary.nvim"
	if vim.fn.isdirectory(plenary_path) == 1 then
		add_to_luapath(plenary_path .. "/lua")
		-- add to runtimepath so plugin/ files are loaded
		vim.opt.runtimepath:append(vim.fn.fnamemodify(plenary_path, ":p"))
	end

	local ascii_ui_path = "./.tests/site/pack/deps/start/ascii-ui.nvim"
	if vim.fn.isdirectory(ascii_ui_path) == 0 then
		vim.fn.system({
			"git",
			"clone",
			"https://github.com/rcasia/ascii-ui.nvim",
			ascii_ui_path,
		})
	end
	if vim.fn.isdirectory(ascii_ui_path) == 1 then
		add_to_luapath(ascii_ui_path .. "/lua")
	end
end
