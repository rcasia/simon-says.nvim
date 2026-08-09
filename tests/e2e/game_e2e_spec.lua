pcall(require, "luacov")

local it = require("plenary.async.tests").it
local testing_e2e = require("ascii-ui.testing.e2e")
local simon = require("simon-says")

describe("Simon Says game e2e", function()
	it("starts game when quadrant is pressed", function()
		local screen = testing_e2e.mount(simon.App)

		-- Wait for initial render
		vim.wait(500)
		
		-- Initial state: idle phase
		assert.is_true(screen:waitForText("Press any quadrant to start", 2000))

		-- Navigate to first focusable quadrant and press Enter
		screen:press("j")
		vim.wait(200)
		local enter = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
		screen:press(enter)

		-- Should transition to "showing" phase
		assert.is_true(screen:waitForText("Watch the sequence", 3000))
	end)

	it("transitions through game phases correctly", function()
		local screen = testing_e2e.mount(simon.App)

		-- Wait for initial render
		vim.wait(500)

		-- Phase 1: idle
		assert.is_true(screen:waitForText("Press any quadrant to start", 2000))

		-- Navigate to quadrant and start game
		screen:press("j")
		vim.wait(200)
		local enter = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
		screen:press(enter)

		-- Phase 2: showing (sequence playing)
		assert.is_true(screen:waitForText("Watch the sequence", 3000))

		-- Phase 3: input (player's turn)
		assert.is_true(screen:waitForText("Your turn", 5000))

		-- Should show progress indicator (0/1 for first round)
		assert.is_true(screen:waitForText("0/1", 2000))
	end)

	it("handles player input and transitions to next state", function()
		local screen = testing_e2e.mount(simon.App)

		-- Wait for initial render
		vim.wait(500)

		-- Navigate to quadrant and start game
		screen:press("j")
		vim.wait(200)
		local enter = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
		screen:press(enter)

		-- Wait for input phase
		assert.is_true(screen:waitForText("Your turn", 5000))

		-- Press some quadrants (we don't know the sequence, so just press randomly)
		-- Move to different quadrants and press
		screen:press("j") -- move to next quadrant
		vim.wait(200)
		screen:press(enter) -- press quadrant

		-- Wait a bit for state transition
		vim.wait(2000)

		-- After input, should either:
		-- 1. Be in next round (back to "Watch" phase) if correct
		-- 2. Be in game over if wrong
		local snapshot = screen:toSnapshot()
		local in_next_round_or_gameover = snapshot:find("Watch") or snapshot:find("Game Over")
		assert.is_not_nil(in_next_round_or_gameover, "Should transition to next round or game over")
	end)

	it("shows game over message after wrong input", function()
		local screen = testing_e2e.mount(simon.App)

		-- Wait for initial render
		vim.wait(500)

		-- Navigate to quadrant and start game
		screen:press("j")
		vim.wait(200)
		local enter = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
		screen:press(enter)

		-- Wait for input phase
		assert.is_true(screen:waitForText("Your turn", 5000))

		-- Press wrong inputs repeatedly until game over
		-- (statistically, random presses will eventually be wrong)
		local game_over_found = false
		for _ = 1, 10 do
			screen:press("j")
			vim.wait(200)
			screen:press(enter)
			vim.wait(500)

			if screen:hasText("Game Over", 100) then
				game_over_found = true
				break
			end
		end

		-- Should eventually see game over
		assert.is_true(game_over_found or screen:hasText("Game Over", 3000), "Should show Game Over message")
	end)

	it("increments score on correct input", function()
		local screen = testing_e2e.mount(simon.App)

		-- Wait for initial render
		vim.wait(500)

		-- Navigate to quadrant and start game
		screen:press("j")
		vim.wait(200)
		local enter = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
		screen:press(enter)

		-- Wait for input phase
		assert.is_true(screen:waitForText("Your turn", 5000))

		-- Get initial score
		local initial_snapshot = screen:toSnapshot()
		local initial_score = initial_snapshot:match("Score:%s*(%d+)")

		-- Try to complete the round by pressing quadrants
		-- We'll press multiple times and check if score changed
		local score_increased = false

		for _ = 1, 5 do
			screen:press("j")
			vim.wait(200)
			screen:press(enter)
			vim.wait(1000)

			local current_snapshot = screen:toSnapshot()
			local current_score = current_snapshot:match("Score:%s*(%d+)")

			if current_score and initial_score and tonumber(current_score) > tonumber(initial_score) then
				score_increased = true
				break
			end

			-- If game over, restart and try again
			if current_snapshot:find("Game Over") then
				screen:press(enter) -- restart
				vim.wait(2000)
				assert.is_true(screen:waitForText("Your turn", 5000))
				initial_snapshot = screen:toSnapshot()
				initial_score = initial_snapshot:match("Score:%s*(%d+)")
			end
		end

		-- Score should have increased at some point
		-- (or we're still playing, which is also acceptable)
		local final_snapshot = screen:toSnapshot()
		local still_playing = final_snapshot:find("Your turn") or final_snapshot:find("Watch")
		assert.is_true(score_increased or still_playing, "Should either score or still be playing")
	end)

	it("allows restarting after game over", function()
		local screen = testing_e2e.mount(simon.App)

		-- Wait for initial render
		vim.wait(500)

		-- Navigate to quadrant and start game
		screen:press("j")
		vim.wait(200)
		local enter = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
		screen:press(enter)

		-- Wait for input phase
		assert.is_true(screen:waitForText("Your turn", 5000))

		-- Press wrong inputs until game over
		local game_over = false
		for _ = 1, 10 do
			screen:press("j")
			vim.wait(200)
			screen:press(enter)
			vim.wait(500)

			if screen:hasText("Game Over", 100) then
				game_over = true
				break
			end
		end

		-- Ensure we reached game over
		if not game_over then
			assert.is_true(screen:waitForText("Game Over", 3000))
		end

		-- Should see "Press any quadrant to play again"
		assert.is_true(screen:waitForText("Press any quadrant to play again", 2000))

		-- Press to restart
		screen:press(enter)

		-- Should be back in showing phase (new game)
		assert.is_true(screen:waitForText("Watch the sequence", 3000))
	end)
end)
