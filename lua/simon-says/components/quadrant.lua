-- A single quadrant cell in the board
--- @module simon-says.components.quadrant

local BufferLine = require("ascii-ui.buffer.bufferline")
local Segment = require("ascii-ui.buffer.segment")
local interaction_type = require("ascii-ui.interaction_type")
local ui = require("ascii-ui")
local colors = require("simon-says.colors")

local FILL = "█"
local QUAD_WIDTH = 12

--- Check if a quadrant should be lit
--- @param quadrantIndex number
--- @param state simon-says.GameState
--- @return boolean
local function isQuadrantLit(quadrantIndex, state)
	if state.gamePhase == "showing" and state.flashVisible then
		return state.sequence[state.currentFlash + 1] == quadrantIndex
	end
	if state.gamePhase == "input" then
		return state.inputFlash == quadrantIndex
	end
	return false
end

local Quadrant = ui.createComponent("Quadrant", function(props)
	local colorPair = colors.COLOR_VALUES[props.colorIndex]
	local lit = isQuadrantLit(props.colorIndex, props.state)
	local color = lit and colorPair.bright or colorPair.dark
	local focusable = props.focusable ~= false
	return {
		BufferLine.new(Segment:new({
			content = string.rep(FILL, QUAD_WIDTH),
			color = { fg = color, bg = color },
			is_focusable = focusable,
			interactions = focusable and {
				[interaction_type.SELECT] = function()
					props.onPress(props.colorIndex)
				end,
			} or {},
		})),
	}
end, { colorIndex = "number", state = "table", onPress = "function", focusable = "boolean" })

return Quadrant
