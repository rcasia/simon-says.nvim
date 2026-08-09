-- Game instructions footer
--- @module simon-says.components.game-instructions

local BufferLine = require("ascii-ui.buffer.bufferline")
local Segment = require("ascii-ui.buffer.segment")
local ui = require("ascii-ui")
local Paragraph = ui.components.Paragraph
local colors = require("simon-says.colors")

local GameInstructions = ui.createComponent("GameInstructions", function()
	return {
		Paragraph({ content = "" }),
		BufferLine.new(
			Segment:new({ content = "  Controls: ", color = colors.TEXT_COLOR }),
			Segment:new({ content = "Navigate with arrow keys/hjkl, select with Enter", color = colors.DIM_COLOR })
		),
	}
end)

return GameInstructions
