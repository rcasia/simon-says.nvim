-- Flash indicator (not currently used in App but available)
--- @module simon-says.components.flash-indicator

local BufferLine = require("ascii-ui.buffer.bufferline")
local Segment = require("ascii-ui.buffer.segment")
local ui = require("ascii-ui")
local colors = require("simon-says.colors")

local FILL = "█"
local QUAD_WIDTH = 12

local FlashIndicator = ui.createComponent("FlashIndicator", function(props)
	local color = colors.COLOR_VALUES[props.colorIndex]
	if not color then
		return {}
	end
	local lit = props.lit
	local fg = lit and color.bright or color.dark
	return {
		BufferLine.new(Segment:new({
			content = string.rep(FILL, QUAD_WIDTH),
			color = { fg = fg, bg = fg },
		})),
	}
end, { colorIndex = "number", lit = "boolean" })

return FlashIndicator
