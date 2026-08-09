pcall(require, "luacov")

local game = require("simon-says.game")
local gameReducer = game.gameReducer
local INITIAL_STATE = game.INITIAL_STATE

--- Helper: create a deterministic state with known sequence
--- @param overrides table|nil
--- @return simon-says.GameState
local function makeState(overrides)
	local state = vim.tbl_extend("force", {
		sequence = { 1, 2, 3 },
		playerIndex = 0,
		score = 0,
		highScore = 0,
		gamePhase = "idle",
		currentFlash = 0,
		flashVisible = false,
		pendingNextRound = false,
		inputFlash = nil,
	}, overrides or {})
	return state
end

describe("gameReducer", function()
	before_each(function()
		math.randomseed(42)
	end)

	describe("START_GAME", function()
		it("initializes game state with random first color", function()
			local state = gameReducer(INITIAL_STATE, { type = "START_GAME" })
			assert.are.equal("showing", state.gamePhase)
			assert.are.equal(0, state.playerIndex)
			assert.are.equal(0, state.score)
			assert.are.equal(1, #state.sequence)
			assert.is_true(state.sequence[1] >= 1 and state.sequence[1] <= 4)
		end)

		it("resets flash and input state", function()
			local state = gameReducer(INITIAL_STATE, { type = "START_GAME" })
			assert.are.equal(0, state.currentFlash)
			assert.is_false(state.flashVisible)
			assert.is_false(state.pendingNextRound)
			assert.is_nil(state.inputFlash)
		end)

		it("preserves highScore from previous state", function()
			local prevState = makeState({ highScore = 10 })
			local state = gameReducer(prevState, { type = "START_GAME" })
			assert.are.equal(10, state.highScore)
		end)

		it("resets score to 0 even if previous game had score", function()
			local prevState = makeState({ score = 5, highScore = 10 })
			local state = gameReducer(prevState, { type = "START_GAME" })
			assert.are.equal(0, state.score)
			assert.are.equal(10, state.highScore)
		end)
	end)

	describe("NEXT_ROUND", function()
		it("adds new random color to sequence", function()
			local state = makeState({ sequence = { 1, 2 } })
			local newState = gameReducer(state, { type = "NEXT_ROUND" })
			assert.are.equal(3, #newState.sequence)
			assert.are.equal(1, newState.sequence[1])
			assert.are.equal(2, newState.sequence[2])
			assert.is_true(newState.sequence[3] >= 1 and newState.sequence[3] <= 4)
		end)

		it("does not mutate original sequence", function()
			local state = makeState({ sequence = { 1, 2 } })
			gameReducer(state, { type = "NEXT_ROUND" })
			assert.are.equal(2, #state.sequence)
		end)

		it("resets playerIndex to 0", function()
			local state = makeState({ playerIndex = 2 })
			local newState = gameReducer(state, { type = "NEXT_ROUND" })
			assert.are.equal(0, newState.playerIndex)
		end)

		it("sets gamePhase to showing", function()
			local state = makeState({ gamePhase = "input" })
			local newState = gameReducer(state, { type = "NEXT_ROUND" })
			assert.are.equal("showing", newState.gamePhase)
		end)

		it("resets flash state", function()
			local state = makeState({ currentFlash = 2, flashVisible = true })
			local newState = gameReducer(state, { type = "NEXT_ROUND" })
			assert.are.equal(0, newState.currentFlash)
			assert.is_false(newState.flashVisible)
		end)

		it("resets pendingNextRound", function()
			local state = makeState({ pendingNextRound = true })
			local newState = gameReducer(state, { type = "NEXT_ROUND" })
			assert.is_false(newState.pendingNextRound)
		end)

		it("resets inputFlash", function()
			local state = makeState({ inputFlash = 3 })
			local newState = gameReducer(state, { type = "NEXT_ROUND" })
			assert.is_nil(newState.inputFlash)
		end)

		it("preserves score and highScore", function()
			local state = makeState({ score = 3, highScore = 5 })
			local newState = gameReducer(state, { type = "NEXT_ROUND" })
			assert.are.equal(3, newState.score)
			assert.are.equal(5, newState.highScore)
		end)
	end)

	describe("CORRECT_INPUT", function()
		it("increments playerIndex", function()
			local state = makeState({ playerIndex = 0, sequence = { 1, 2, 3 } })
			local newState = gameReducer(state, { type = "CORRECT_INPUT" })
			assert.are.equal(1, newState.playerIndex)
		end)

		it("does not update score when round not complete", function()
			local state = makeState({ playerIndex = 0, score = 0, sequence = { 1, 2, 3 } })
			local newState = gameReducer(state, { type = "CORRECT_INPUT" })
			assert.are.equal(0, newState.score)
		end)

		it("detects round completion when playerIndex reaches sequence length", function()
			local state = makeState({ playerIndex = 2, score = 0, sequence = { 1, 2, 3 } })
			local newState = gameReducer(state, { type = "CORRECT_INPUT" })
			assert.are.equal(3, newState.playerIndex)
			assert.are.equal(1, newState.score)
			assert.is_true(newState.pendingNextRound)
		end)

		it("updates highScore when score exceeds it", function()
			local state = makeState({
				playerIndex = 2,
				score = 5,
				highScore = 5,
				sequence = { 1, 2, 3 },
			})
			local newState = gameReducer(state, { type = "CORRECT_INPUT" })
			assert.are.equal(6, newState.score)
			assert.are.equal(6, newState.highScore)
		end)

		it("does not lower highScore when score is below it", function()
			local state = makeState({
				playerIndex = 0,
				score = 0,
				highScore = 10,
				sequence = { 1 },
			})
			local newState = gameReducer(state, { type = "CORRECT_INPUT" })
			assert.are.equal(1, newState.score)
			assert.are.equal(10, newState.highScore)
		end)

		it("does not set pendingNextRound when round not complete", function()
			local state = makeState({ playerIndex = 0, sequence = { 1, 2, 3 } })
			local newState = gameReducer(state, { type = "CORRECT_INPUT" })
			assert.is_false(newState.pendingNextRound)
		end)

		it("handles single-element sequence", function()
			local state = makeState({ playerIndex = 0, score = 0, sequence = { 2 } })
			local newState = gameReducer(state, { type = "CORRECT_INPUT" })
			assert.are.equal(1, newState.playerIndex)
			assert.are.equal(1, newState.score)
			assert.is_true(newState.pendingNextRound)
		end)
	end)

	describe("WRONG_INPUT", function()
		it("sets gamePhase to gameover", function()
			local state = makeState({ gamePhase = "input" })
			local newState = gameReducer(state, { type = "WRONG_INPUT" })
			assert.are.equal("gameover", newState.gamePhase)
		end)

		it("clears inputFlash", function()
			local state = makeState({ gamePhase = "input", inputFlash = 2 })
			local newState = gameReducer(state, { type = "WRONG_INPUT" })
			assert.is_nil(newState.inputFlash)
		end)

		it("preserves sequence, score, and highScore", function()
			local state = makeState({
				gamePhase = "input",
				sequence = { 1, 2, 3 },
				score = 5,
				highScore = 10,
				playerIndex = 1,
			})
			local newState = gameReducer(state, { type = "WRONG_INPUT" })
			assert.are.same({ 1, 2, 3 }, newState.sequence)
			assert.are.equal(5, newState.score)
			assert.are.equal(10, newState.highScore)
			assert.are.equal(1, newState.playerIndex)
		end)
	end)

	describe("SHOW_FLASH", function()
		it("sets flashVisible to true", function()
			local state = makeState({ flashVisible = false })
			local newState = gameReducer(state, { type = "SHOW_FLASH" })
			assert.is_true(newState.flashVisible)
		end)

		it("preserves other state", function()
			local state = makeState({ flashVisible = false, score = 3 })
			local newState = gameReducer(state, { type = "SHOW_FLASH" })
			assert.are.equal(3, newState.score)
			assert.are.equal("idle", newState.gamePhase)
		end)
	end)

	describe("HIDE_FLASH", function()
		it("sets flashVisible to false", function()
			local state = makeState({ flashVisible = true })
			local newState = gameReducer(state, { type = "HIDE_FLASH" })
			assert.is_false(newState.flashVisible)
		end)
	end)

	describe("ADVANCE_FLASH", function()
		it("increments currentFlash", function()
			local state = makeState({ currentFlash = 0 })
			local newState = gameReducer(state, { type = "ADVANCE_FLASH" })
			assert.are.equal(1, newState.currentFlash)
		end)

		it("sets flashVisible to true", function()
			local state = makeState({ currentFlash = 1, flashVisible = false })
			local newState = gameReducer(state, { type = "ADVANCE_FLASH" })
			assert.is_true(newState.flashVisible)
		end)

		it("increments multiple times correctly", function()
			local state = makeState({ currentFlash = 0 })
			state = gameReducer(state, { type = "ADVANCE_FLASH" })
			state = gameReducer(state, { type = "ADVANCE_FLASH" })
			state = gameReducer(state, { type = "ADVANCE_FLASH" })
			assert.are.equal(3, state.currentFlash)
		end)
	end)

	describe("ENTER_INPUT_PHASE", function()
		it("sets gamePhase to input", function()
			local state = makeState({ gamePhase = "showing" })
			local newState = gameReducer(state, { type = "ENTER_INPUT_PHASE" })
			assert.are.equal("input", newState.gamePhase)
		end)

		it("preserves other state", function()
			local state = makeState({ gamePhase = "showing", score = 3, sequence = { 1, 2 } })
			local newState = gameReducer(state, { type = "ENTER_INPUT_PHASE" })
			assert.are.equal(3, newState.score)
			assert.are.same({ 1, 2 }, newState.sequence)
		end)
	end)

	describe("INPUT_FLASH", function()
		it("sets inputFlash to given colorIndex", function()
			local state = makeState()
			local newState = gameReducer(state, { type = "INPUT_FLASH", colorIndex = 3 })
			assert.are.equal(3, newState.inputFlash)
		end)
	end)

	describe("CLEAR_INPUT_FLASH", function()
		it("sets inputFlash to nil", function()
			local state = makeState({ inputFlash = 2 })
			local newState = gameReducer(state, { type = "CLEAR_INPUT_FLASH" })
			assert.is_nil(newState.inputFlash)
		end)
	end)

	describe("CLEAR_PENDING_ROUND", function()
		-- Note: CLEAR_PENDING_ROUND is not implemented in the reducer.
		-- The pendingNextRound is cleared by NEXT_ROUND action.
		-- This test verifies that unknown actions return state unchanged.
		it("is handled by NEXT_ROUND which resets pendingNextRound", function()
			local state = makeState({ pendingNextRound = true })
			local newState = gameReducer(state, { type = "NEXT_ROUND" })
			assert.is_false(newState.pendingNextRound)
		end)
	end)

	describe("unknown action", function()
		it("returns state unchanged", function()
			local state = makeState()
			local newState = gameReducer(state, { type = "NONEXISTENT" })
			assert.are.equal(state, newState)
		end)
	end)

	describe("edge cases", function()
		it("handles empty sequence on INITIAL_STATE", function()
			assert.are.equal(0, #INITIAL_STATE.sequence)
			assert.are.equal("idle", INITIAL_STATE.gamePhase)
		end)

		it("handles multiple consecutive CORRECT_INPUT actions", function()
			local state = makeState({ playerIndex = 0, score = 0, sequence = { 1, 2 } })
			state = gameReducer(state, { type = "CORRECT_INPUT" })
			assert.are.equal(1, state.playerIndex)
			assert.are.equal(0, state.score)
			state = gameReducer(state, { type = "CORRECT_INPUT" })
			assert.are.equal(2, state.playerIndex)
			assert.are.equal(1, state.score)
			assert.is_true(state.pendingNextRound)
		end)

		it("high score persists across multiple games", function()
			-- Game 1: score 2
			local state = gameReducer(INITIAL_STATE, { type = "START_GAME" })
			state = makeState({
				highScore = state.highScore,
				score = 0,
				playerIndex = 0,
				sequence = { 1 },
			})
			state = gameReducer(state, { type = "CORRECT_INPUT" })
			assert.are.equal(1, state.score)
			assert.are.equal(1, state.highScore)

			-- Start game 2, high score should persist
			state.highScore = 1
			state = gameReducer(state, { type = "START_GAME" })
			assert.are.equal(1, state.highScore)
			assert.are.equal(0, state.score)
		end)

		it("CORRECT_INPUT on last step of long sequence completes round", function()
			local state = makeState({
				playerIndex = 4,
				score = 4,
				highScore = 4,
				sequence = { 1, 2, 3, 4, 1 },
			})
			local newState = gameReducer(state, { type = "CORRECT_INPUT" })
			assert.are.equal(5, newState.playerIndex)
			assert.are.equal(5, newState.score)
			assert.are.equal(5, newState.highScore)
			assert.is_true(newState.pendingNextRound)
		end)
	end)
end)
