pcall(require, "luacov")

local testing = require("ascii-ui.testing")
local ui = require("ascii-ui")
local SimonBoard = require("simon-says.components.simon-board")

describe("SimonBoard", function()
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

	it("renders board with borders", function()
		local App = ui.createComponent("App", function()
			return SimonBoard({ state = makeState(), onInput = function() end })
		end)
		local screen = testing.render(App)
		assert(screen:hasText("╔"))
		assert(screen:hasText("╗"))
		assert(screen:hasText("╚"))
		assert(screen:hasText("╝"))
	end)

	it("renders filled quadrants", function()
		local App = ui.createComponent("App", function()
			return SimonBoard({ state = makeState(), onInput = function() end })
		end)
		local screen = testing.render(App)
		assert(screen:hasText("█"))
	end)

	it("has focusable quadrants on first row", function()
		local App = ui.createComponent("App", function()
			return SimonBoard({ state = makeState(), onInput = function() end })
		end)
		local screen = testing.render(App)
		local focusables = screen:getAllFocusable()
		assert.is_true(#focusables > 0)
	end)
end)
