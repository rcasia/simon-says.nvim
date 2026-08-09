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
			flashVisible = true, -- Start with flash visible immediately
			pendingNextRound = false,
			inputFlash = nil,
		}
	elseif action.type == "NEXT_ROUND" then
		local newSeq = vim.list_extend({}, state.sequence)
		table.insert(newSeq, math.random(1, 4))
		local new_state = vim.tbl_extend("force", state, {
			sequence = newSeq,
			playerIndex = 0,
			gamePhase = "showing",
			currentFlash = 0,
			flashVisible = true, -- Start with flash visible immediately
			pendingNextRound = false,
		})
		new_state.inputFlash = nil
		return new_state
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
		local new_state = vim.tbl_extend("force", state, { gamePhase = "gameover" })
		new_state.inputFlash = nil
		return new_state
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
		local new_state = vim.tbl_extend("force", state, {})
		new_state.inputFlash = nil
		return new_state
	elseif action.type == "PLAYER_INPUT" then
		-- Guard: ignore input if not in input phase
		if state.gamePhase ~= "input" then
			return state
		end
		local colorIndex = action.colorIndex
		-- Set input flash for visual feedback
		local newState = vim.tbl_extend("force", state, { inputFlash = colorIndex })
		-- Check if the input matches the expected sequence position
		if state.sequence[state.playerIndex + 1] == colorIndex then
			-- Correct input
			local newPlayerIndex = state.playerIndex + 1
			local roundComplete = newPlayerIndex >= #state.sequence
			local newScore = roundComplete and state.score + 1 or state.score
			local newHighScore = math.max(state.highScore, newScore)
			return vim.tbl_extend("force", newState, {
				playerIndex = newPlayerIndex,
				score = newScore,
				highScore = newHighScore,
				pendingNextRound = roundComplete,
			})
		else
			-- Wrong input — game over, clear flash
			newState.inputFlash = nil
			return vim.tbl_extend("force", newState, { gamePhase = "gameover" })
		end
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
		dispatch({ type = "PLAYER_INPUT", colorIndex = colorIndex })
	end

	-- Note: flashVisible is now set to true directly in START_GAME and NEXT_ROUND reducers
	-- This avoids an infinite loop where useEffect would dispatch SHOW_FLASH repeatedly

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

return {
	useSimonGame = useSimonGame,
	gameReducer = gameReducer,
	INITIAL_STATE = INITIAL_STATE,
}
