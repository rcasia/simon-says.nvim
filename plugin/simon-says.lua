-- Entry point for Neovim plugin
if vim.g.loaded_simon_says then
	return
end
vim.g.loaded_simon_says = 1

vim.api.nvim_create_user_command("SimonSays", function()
	require("simon-says").start()
end, { desc = "Start Simon Says game" })
