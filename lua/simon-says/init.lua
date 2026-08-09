--- Simon Says: A memory game where you repeat an increasingly long sequence of colors.
--- Built with ascii-ui.nvim.
--- @module simon-says

local ui = require("ascii-ui")
local Paragraph = ui.components.Paragraph
local components = require("simon-says.components")
local game = require("simon-says.game")
local useSimonGame = game.useSimonGame

local M = {}

--- Main App component
local App = ui.createComponent("App", function()
	local game = useSimonGame()
	local state = game.state

	local function handleQuadrantPress(colorIndex)
		if state.gamePhase == "idle" or state.gamePhase == "gameover" then
			game.startGame()
		elseif state.gamePhase == "input" then
			game.handleInput(colorIndex)
		end
	end

	return {
		components.Title(),
		Paragraph({ content = "" }),
		components.ScoreDisplay({ score = state.score, highScore = state.highScore }),
		Paragraph({ content = "" }),
		components.SimonBoard({ state = state, onInput = handleQuadrantPress }),
		Paragraph({ content = "" }),
		components.StatusMessage({
			gamePhase = state.gamePhase,
			playerIndex = state.playerIndex,
			sequenceLength = #state.sequence,
			score = state.score,
		}),
		components.GameInstructions(),
	}
end)

--- Start the Simon Says game
function M.start()
	ui.mount(App)
end

return M
