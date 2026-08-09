-- Title banner component
--- @module simon-says.components.title

local BufferLine = require("ascii-ui.buffer.bufferline")
local Segment = require("ascii-ui.buffer.segment")
local ui = require("ascii-ui")
local colors = require("simon-says.colors")

local Title = ui.createComponent("Title", function()
	return {
		BufferLine.new(Segment:new({
			content = "╔════════════════════════════════════╗",
			color = colors.ACCENT_COLOR,
		})),
		BufferLine.new(
			Segment:new({ content = "║        SIMON SAYS MEMORY GAME      ║", color = colors.ACCENT_COLOR })
		),
		BufferLine.new(Segment:new({
			content = "╚════════════════════════════════════╝",
			color = colors.ACCENT_COLOR,
		})),
	}
end)

return Title
