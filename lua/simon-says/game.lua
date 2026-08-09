--- Simon Says game logic as a custom hook.
--- Encapsulates all game state, reducer, and timing logic.
--- @module simon-says.game

local ui = require("ascii-ui")
local useReducer = ui.hooks.useReducer
local useEffect = ui.hooks.useEffect
local useTimeout = ui.hooks.useTimeout

--- @class simon-says.GameState
--- @field sequence number[]
--- @field playerIndex number
--- @field score number
--- @field highScore number
--- @field gamePhase string
--- @field currentFlash number
--- @field flashVisible boolean
--- @field pendingNextRound boolean
--- @field inputFlash number|nil

--- @class simon-says.GameAction
--- @field type string

--- @param state simon-says.GameState
--- @param action simon-says.GameAction
--- @return simon-says.GameState
local function gameReducer(state, action)
	if action.type == "START_GAME" then
		return {
			sequence = { math.random(1, 4) },
			playerIndex = 0,
			score = 0,
			highScore = state.highScore,
			gamePhase = "showing",
			currentFlash = 0,
			flashVisible = false,
			pendingNextRound = false,
			inputFlash = nil,
		}
	elseif action.type == "NEXT_ROUND" then
		local newSeq = vim.list_extend({}, state.sequence)
		table.insert(newSeq, math.random(1, 4))
		return vim.tbl_extend("force", state, {
			sequence = newSeq,
			playerIndex = 0,
			gamePhase = "showing",
			currentFlash = 0,
			flashVisible = false,
			pendingNextRound = false,
			inputFlash = nil,
		})
	elseif action.type == "CORRECT_INPUT" then
		local newPlayerIndex = state.playerIndex + 1
		local roundComplete = newPlayerIndex >= #state.sequence
		local newScore = roundComplete and state.score + 1 or state.score
		local newHighScore = math.max(state.highScore, newScore)
		return vim.tbl_extend("force", state, {
			playerIndex = newPlayerIndex,
			score = newScore,
			highScore = newHighScore,
			pendingNextRound = roundComplete,
		})
	elseif action.type == "WRONG_INPUT" then
		return vim.tbl_extend("force", state, { gamePhase = "gameover", inputFlash = nil })
	elseif action.type == "SHOW_FLASH" then
		return vim.tbl_extend("force", state, { flashVisible = true })
	elseif action.type == "HIDE_FLASH" then
		return vim.tbl_extend("force", state, { flashVisible = false })
	elseif action.type == "ADVANCE_FLASH" then
		return vim.tbl_extend("force", state, {
			currentFlash = state.currentFlash + 1,
			flashVisible = true,
		})
	elseif action.type == "ENTER_INPUT_PHASE" then
		return vim.tbl_extend("force", state, { gamePhase = "input" })
	elseif action.type == "INPUT_FLASH" then
		return vim.tbl_extend("force", state, { inputFlash = action.colorIndex })
	elseif action.type == "CLEAR_INPUT_FLASH" then
		return vim.tbl_extend("force", state, { inputFlash = nil })
	end
	return state
end

local INITIAL_STATE = {
	sequence = {},
	playerIndex = 0,
	score = 0,
	highScore = 0,
	gamePhase = "idle",
	currentFlash = 0,
	flashVisible = false,
	pendingNextRound = false,
	inputFlash = nil,
}

--- Custom hook: encapsulates all Simon game state and logic.
--- @return {state: simon-says.GameState, startGame: fun(), handleInput: fun(number)}
local function useSimonGame()
	local state, dispatch = useReducer(gameReducer, INITIAL_STATE)

	--- Start a new game
	local function startGame()
		dispatch({ type = "START_GAME" })
	end

	--- Handle player input on a quadrant
	--- @param colorIndex number
	local function handleInput(colorIndex)
		if state.gamePhase ~= "input" then
			return
		end
		dispatch({ type = "INPUT_FLASH", colorIndex = colorIndex })
		if state.sequence[state.playerIndex + 1] == colorIndex then
			dispatch({ type = "CORRECT_INPUT" })
		else
			dispatch({ type = "WRONG_INPUT" })
		end
	end

	-- Start showing first flash when entering "showing" phase
	useEffect(function()
		if state.gamePhase == "showing" and state.currentFlash == 0 and not state.flashVisible then
			dispatch({ type = "SHOW_FLASH" })
		end
	end, { state.gamePhase })

	-- Hide flash after 600ms when visible
	useTimeout(function()
		dispatch({ type = "HIDE_FLASH" })
	end, state.flashVisible and state.gamePhase == "showing" and 600 or nil)

	-- Advance to next flash after 300ms when hidden
	useTimeout(
		function()
			dispatch({ type = "ADVANCE_FLASH" })
		end,
		not state.flashVisible and state.gamePhase == "showing" and state.currentFlash < #state.sequence and 300 or nil
	)

	-- Transition to input phase after 500ms when sequence complete
	useTimeout(
		function()
			dispatch({ type = "ENTER_INPUT_PHASE" })
		end,
		not state.flashVisible and state.gamePhase == "showing" and state.currentFlash >= #state.sequence and 500 or nil
	)

	-- Start next round after 1000ms when pending
	useTimeout(function()
		dispatch({ type = "NEXT_ROUND" })
	end, state.pendingNextRound and 1000 or nil)

	-- Clear input flash after 300ms
	useTimeout(function()
		dispatch({ type = "CLEAR_INPUT_FLASH" })
	end, state.inputFlash ~= nil and 300 or nil)

	return {
		state = state,
		startGame = startGame,
		handleInput = handleInput,
	}
end

return useSimonGame
