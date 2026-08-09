pcall(require, "luacov")

local it = require("plenary.async.tests").it
local testing_e2e = require("ascii-ui.testing.e2e")
local simon = require("simon-says")

describe("Simon Says game e2e", function()
	it("renders initial state with title and start message", function()
		local screen = testing_e2e.mount(simon.App)

		-- Wait for initial render
		assert.is_true(screen:waitForText("SIMON SAYS", 2000))
		assert.is_true(screen:waitForText("Press any quadrant to start", 2000))
		assert.is_true(screen:waitForText("Score:", 2000))
		assert.is_true(screen:waitForText("High Score:", 2000))
	end)

	it("renders game instructions", function()
		local screen = testing_e2e.mount(simon.App)

		assert.is_true(screen:waitForText("Controls:", 2000))
		assert.is_true(screen:waitForText("Navigate", 2000))
	end)

	it("renders the game board with quadrants", function()
		local screen = testing_e2e.mount(simon.App)

		-- Check for board borders
		assert.is_true(screen:waitForText("╔", 2000))
		assert.is_true(screen:waitForText("╗", 2000))
		assert.is_true(screen:waitForText("╚", 2000))
		assert.is_true(screen:waitForText("╝", 2000))
		-- Check for filled quadrants
		assert.is_true(screen:waitForText("█", 2000))
	end)
end)
