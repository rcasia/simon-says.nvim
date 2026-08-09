pcall(require, "luacov")

local testing = require("ascii-ui.testing")
local ui = require("ascii-ui")
local Quadrant = require("simon-says.components.quadrant")

describe("Quadrant", function()
	local function makeState(overrides)
		return vim.tbl_extend("force", {
			sequence = {},
			playerIndex = 0,
			score = 0,
			highScore = 0,
			gamePhase = "idle",
			currentFlash = 0,
			flashVisible = false,
			pendingNextRound = false,
			inputFlash = nil,
		}, overrides or {})
	end

	it("renders filled blocks", function()
		local pressed = {}
		local App = ui.createComponent("App", function()
			return Quadrant({ colorIndex = 1, state = makeState(), onPress = function(idx)
				table.insert(pressed, idx)
			end })
		end)
		local screen = testing.render(App)
		assert(screen:hasText("█"))
	end)

	it("is focusable by default", function()
		local App = ui.createComponent("App", function()
			return Quadrant({ colorIndex = 1, state = makeState(), onPress = function() end })
		end)
		local screen = testing.render(App)
		assert.is_true(screen:hasFocusable("█"))
	end)

	it("is not focusable when focusable=false", function()
		local App = ui.createComponent("App", function()
			return Quadrant({ colorIndex = 1, state = makeState(), onPress = function() end, focusable = false })
		end)
		local screen = testing.render(App)
		assert.is_false(screen:hasFocusable("█"))
	end)

	it("calls onPress with colorIndex when selected", function()
		local pressed = {}
		local App = ui.createComponent("App", function()
			return Quadrant({
				colorIndex = 2,
				state = makeState(),
				onPress = function(idx)
					table.insert(pressed, idx)
				end,
			})
		end)
		local screen = testing.render(App)
		screen:select("█")
		assert.are.same({ 2 }, pressed)
	end)
end)
