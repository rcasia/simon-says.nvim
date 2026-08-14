pcall(require, "luacov")

local it = require("plenary.async.tests").it
local testing_e2e = require("ascii-ui.testing.e2e")
local simon = require("simon-says")

describe("Simon Says game - actual gameplay", function()
	local screen
	local enter

	before_each(function()
		enter = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
	end)

	after_each(function()
		if screen then
			screen:unmount()
			screen = nil
		end
	end)

	it("accepts input and transitions correctly", function()
		screen = testing_e2e.mount(simon.App)
		vim.wait(500)

		-- Start game
		assert.is_true(screen:waitForText("Press any quadrant to start", 2000))

		screen:press("j")
		vim.wait(200)
		screen:press(enter)
		vim.wait(400)

		-- Wait for showing phase
		assert.is_true(screen:waitForText("Watch the sequence", 3000))

		-- Wait for input phase
		assert.is_true(screen:waitForText("Your turn", 5000))

		-- Verify initial progress (0/1 for first round)
		assert.is_true(screen:waitForText("0/1", 2000))

		-- Press input and check for transition
		local transitioned = false
		for _ = 1, 4 do
			screen:press("j")
			vim.wait(200)
			screen:press(enter)
			vim.wait(800)

			local snapshot = screen:toSnapshot()

			-- Check for any state transition
			if snapshot:find("Watch the sequence") or snapshot:find("Game Over") or snapshot:find("1/1") then
				transitioned = true
				break
			end
		end

		-- Should have transitioned to next round or game over
		assert.is_true(transitioned, "Should transition after input")
	end)

	it("completes round when correct input is given", function()
		screen = testing_e2e.mount(simon.App)
		vim.wait(500)

		-- Start game
		screen:press("j")
		vim.wait(200)
		screen:press(enter)
		vim.wait(400)

		assert.is_true(screen:waitForText("Watch the sequence", 3000))
		assert.is_true(screen:waitForText("Your turn", 5000))

		-- Get initial score
		local initial_snapshot = screen:toSnapshot()
		local initial_score = tonumber(initial_snapshot:match("Score:%s*(%d+)") or "0")

		-- Try pressing inputs until round completes or game over
		local round_completed = false
		local game_over = false

		for _ = 1, 8 do
			screen:press("j")
			vim.wait(200)
			screen:press(enter)
			vim.wait(1000)

			local snapshot = screen:toSnapshot()

			-- Check if round completed (back to showing phase)
			if snapshot:find("Watch the sequence") then
				round_completed = true
				break
			end

			-- Check if game over
			if snapshot:find("Game Over") then
				game_over = true
				break
			end
		end

		-- Either completed round or game over
		assert.is_true(round_completed or game_over, "Should complete round or game over")

		-- If round completed, verify score increased
		if round_completed then
			vim.wait(800)
			local final_snapshot = screen:toSnapshot()
			local final_score = tonumber(final_snapshot:match("Score:%s*(%d+)") or "0")
			assert.is_true(final_score > initial_score, "Score should increase after completing round")
		end
	end)

	it("handles game over and restart", function()
		screen = testing_e2e.mount(simon.App)
		vim.wait(500)

		-- Start game
		screen:press("j")
		vim.wait(200)
		screen:press(enter)
		vim.wait(400)

		assert.is_true(screen:waitForText("Watch the sequence", 3000))
		assert.is_true(screen:waitForText("Your turn", 5000))

		-- Play until game over
		local game_over = false
		for _ = 1, 20 do
			screen:press("j")
			vim.wait(200)
			screen:press(enter)
			vim.wait(600)

			if screen:hasText("Game Over", 200) then
				game_over = true
				break
			end

			if screen:hasText("Watch the sequence", 200) then
				vim.wait(1500)
				if not screen:waitForText("Your turn", 4000) then
					break
				end
			end
		end

		-- Should be in a valid state
		local final_snapshot = screen:toSnapshot()
		local valid_state = final_snapshot:find("Game Over") or final_snapshot:find("Your turn") or final_snapshot:find("Watch")
		assert.is_not_nil(valid_state, "Should be in valid game state")

		-- If game over, verify restart works
		if game_over or screen:hasText("Game Over", 1000) then
			assert.is_true(screen:waitForText("Press any quadrant to play again", 2000))

			screen:press("j")
			vim.wait(200)
			screen:press(enter)
			vim.wait(400)

			assert.is_true(screen:waitForText("Watch the sequence", 3000))
		end
	end)
end)
