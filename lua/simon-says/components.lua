--- Simon Says UI components.
--- @module simon-says.components

local BufferLine = require("ascii-ui.buffer.bufferline")
local Segment = require("ascii-ui.buffer.segment")
local interaction_type = require("ascii-ui.interaction_type")
local ui = require("ascii-ui")
local Paragraph = ui.components.Paragraph
local colors = require("simon-says.colors")

-- Quadrant dimensions
local QUAD_WIDTH = 12
local QUAD_HEIGHT = 4
local FILL = "█"

--- Title banner component
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

--- Score and high score display
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

--- Status message based on game phase
local StatusMessage = ui.createComponent("StatusMessage", function(props)
	return {
		props.gamePhase == "idle" and Paragraph({ content = "  Press any quadrant to start!" }) or nil,
		props.gamePhase == "showing" and Paragraph({ content = "  Watch the sequence..." }) or nil,
		props.gamePhase == "input" and BufferLine.new(
			Segment:new({ content = "  Your turn! Repeat (", color = colors.TEXT_COLOR }),
			Segment:new({ content = tostring(props.playerIndex), color = colors.ACCENT_COLOR }),
			Segment:new({ content = "/" }),
			Segment:new({ content = tostring(props.sequenceLength), color = colors.ACCENT_COLOR }),
			Segment:new({ content = ")" })
		) or nil,
		props.gamePhase == "gameover" and BufferLine.new(Segment:new({
			content = "  Game Over! Final Score: " .. props.score,
			color = colors.COLORS.RED.bright,
		})) or nil,
		props.gamePhase == "gameover" and Paragraph({ content = "  Press any quadrant to play again." }) or nil,
	}
end, { gamePhase = "string", playerIndex = "number", sequenceLength = "number", score = "number" })

--- Flash indicator (not currently used in App but available)
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

--- A single quadrant cell in the board
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

--- The 2x2 Simon quadrant board with double-line borders
local SimonBoard = ui.createComponent("SimonBoard", function(props)
	local state = props.state
	local onInput = props.onInput

	local hLine = string.rep("═", QUAD_WIDTH)

	--- Create a border segment
	local function makeBorderSeg(content)
		return Segment:new({ content = content, color = colors.BORDER_COLOR })
	end

	--- Create one row of two quadrants with borders
	local function makeQuadRow(leftIdx, rightIdx, isFirstLine)
		return BufferLine.new(
			makeBorderSeg("║"),
			Quadrant({ colorIndex = leftIdx, state = state, onPress = onInput, focusable = isFirstLine }),
			makeBorderSeg("║"),
			Quadrant({ colorIndex = rightIdx, state = state, onPress = onInput, focusable = isFirstLine }),
			makeBorderSeg("║")
		)
	end

	-- Build board lines: top border, top row, middle border, bottom row, bottom border
	local topBorder = { BufferLine.new(makeBorderSeg("╔" .. hLine .. "╦" .. hLine .. "╗")) }
	local topRows = ui.map(vim.fn.range(1, QUAD_HEIGHT), function(_, row)
		return makeQuadRow(1, 2, row == 1) -- GREEN (left), RED (right)
	end)
	local midBorder = { BufferLine.new(makeBorderSeg("╠" .. hLine .. "╬" .. hLine .. "╣")) }
	local bottomRows = ui.map(vim.fn.range(1, QUAD_HEIGHT), function(_, row)
		return makeQuadRow(3, 4, row == 1) -- YELLOW (left), BLUE (right)
	end)
	local bottomBorder = { BufferLine.new(makeBorderSeg("╚" .. hLine .. "╩" .. hLine .. "╝")) }

	local lines = {}
	vim.list_extend(lines, topBorder)
	vim.list_extend(lines, topRows)
	vim.list_extend(lines, midBorder)
	vim.list_extend(lines, bottomRows)
	vim.list_extend(lines, bottomBorder)
	return lines
end, { state = "table", onInput = "function" })

--- Game instructions footer
local GameInstructions = ui.createComponent("GameInstructions", function()
	return {
		Paragraph({ content = "" }),
		BufferLine.new(
			Segment:new({ content = "  Controls: ", color = colors.TEXT_COLOR }),
			Segment:new({ content = "Navigate with arrow keys/hjkl, select with Enter", color = colors.DIM_COLOR })
		),
	}
end)

return {
	Title = Title,
	ScoreDisplay = ScoreDisplay,
	StatusMessage = StatusMessage,
	FlashIndicator = FlashIndicator,
	Quadrant = Quadrant,
	SimonBoard = SimonBoard,
	GameInstructions = GameInstructions,
}
