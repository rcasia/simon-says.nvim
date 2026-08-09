-- Status message based on game phase
--- @module simon-says.components.status-message

local BufferLine = require("ascii-ui.buffer.bufferline")
local Segment = require("ascii-ui.buffer.segment")
local ui = require("ascii-ui")
local Paragraph = ui.components.Paragraph
local colors = require("simon-says.colors")

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

return StatusMessage
