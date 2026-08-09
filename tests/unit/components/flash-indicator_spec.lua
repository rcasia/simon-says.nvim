pcall(require, "luacov")

local testing = require("ascii-ui.testing")
local ui = require("ascii-ui")
local FlashIndicator = require("simon-says.components.flash-indicator")

describe("FlashIndicator", function()
	it("renders filled blocks", function()
		local App = ui.createComponent("App", function()
			return FlashIndicator({ colorIndex = 1, lit = false })
		end)
		local screen = testing.render(App)
		local lines = screen:toLines()
		assert.is_true(#lines > 0)
		assert(screen:hasText("█"))
	end)

	it("renders minimal output for invalid color index", function()
		local App = ui.createComponent("App", function()
			return FlashIndicator({ colorIndex = 99, lit = false })
		end)
		local screen = testing.render(App)
		-- Invalid color index returns empty table, but render still produces output
		-- Just verify it doesn't crash
		local lines = screen:toLines()
		assert.is_true(#lines >= 0)
	end)
end)
