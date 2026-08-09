-- The 2x2 Simon quadrant board with double-line borders
--- @module simon-says.components.simon-board

local BufferLine = require("ascii-ui.buffer.bufferline")
local Segment = require("ascii-ui.buffer.segment")
local interaction_type = require("ascii-ui.interaction_type")
local ui = require("ascii-ui")
local colors = require("simon-says.colors")

local QUAD_WIDTH = 12
local QUAD_HEIGHT = 4
local FILL = "█"

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

local SimonBoard = ui.createComponent("SimonBoard", function(props)
	local state = props.state
	local onInput = props.onInput

	local hLine = string.rep("═", QUAD_WIDTH)

	--- Create a border segment
	local function makeBorderSeg(content)
		return Segment:new({ content = content, color = colors.BORDER_COLOR })
	end

	--- Create a quadrant segment (inlined from Quadrant component)
	local function makeQuadrantSeg(colorIndex, focusable)
		local colorPair = colors.COLOR_VALUES[colorIndex]
		local lit = isQuadrantLit(colorIndex, state)
		local color = lit and colorPair.bright or colorPair.dark
		return Segment:new({
			content = string.rep(FILL, QUAD_WIDTH),
			color = { fg = color, bg = color },
			is_focusable = focusable,
			interactions = focusable and {
				[interaction_type.SELECT] = function()
					onInput(colorIndex)
				end,
			} or {},
		})
	end

	--- Create one row of two quadrants with borders
	local function makeQuadRow(leftIdx, rightIdx, isFirstLine)
		return BufferLine.new(
			makeBorderSeg("║"),
			makeQuadrantSeg(leftIdx, isFirstLine),
			makeBorderSeg("║"),
			makeQuadrantSeg(rightIdx, isFirstLine),
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

return SimonBoard
