-- Score and high score display
--- @module simon-says.components.score-display

local BufferLine = require("ascii-ui.buffer.bufferline")
local Segment = require("ascii-ui.buffer.segment")
local ui = require("ascii-ui")
local colors = require("simon-says.colors")

local ScoreDisplay = ui.createComponent("ScoreDisplay", function(props)
	return {
		BufferLine.new(
			Segment:new({ content = "  Score: ", color = colors.TEXT_COLOR }),
			Segment:new({ content = tostring(props.score), color = colors.ACCENT_COLOR }),
			Segment:new({ content = "    High Score: ", color = colors.TEXT_COLOR }),
			Segment:new({ content = tostring(props.highScore), color = colors.ACCENT_COLOR })
		),
	}
end, { score = "number", highScore = "number" })

return ScoreDisplay
