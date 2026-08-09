pcall(require, "luacov")

local game = require("simon-says.game")
local gameReducer = game.gameReducer
local INITIAL_STATE = game.INITIAL_STATE

--- Helper: create a deterministic state with known values.
--- Simulates a game mid-play by overriding specific fields.
--- @param overrides table|nil
--- @return simon-says.GameState
local function makeState(overrides)
	return vim.tbl_extend("force", {
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
end

describe("Simon Says game", function()
	before_each(function()
		math.randomseed(42)
	end)

	describe("starting a new game", function()
		it("initializes with a sequence of 1", function()
			local state = gameReducer(INITIAL_STATE, { type = "START_GAME" })
			assert.are.equal(1, #state.sequence)
			assert.are.equal("showing", state.gamePhase)
			assert.are.equal(0, state.score)
		end)

		it("generates a valid color (1-4)", function()
			local state = gameReducer(INITIAL_STATE, { type = "START_GAME" })
			assert.is_true(state.sequence[1] >= 1 and state.sequence[1] <= 4)
		end)

		it("resets player progress", function()
			local state = gameReducer(INITIAL_STATE, { type = "START_GAME" })
			assert.are.equal(0, state.playerIndex)
		end)

		it("preserves high score from previous game", function()
			local prevState = makeState({ highScore = 5 })
			local state = gameReducer(prevState, { type = "START_GAME" })
			assert.are.equal(5, state.highScore)
			assert.are.equal(0, state.score)
		end)
	end)

	describe("playing a round", function()
		it("scores when player completes the sequence", function()
			-- Set up: game in input phase with known sequence of 1
			local state = makeState({
				sequence = { 1 },
				gamePhase = "input",
				playerIndex = 0,
			})

			-- Player inputs correct color
			state = gameReducer(state, { type = "CORRECT_INPUT" })
			assert.are.equal(1, state.score)
		end)

		it("does not score mid-round (only on round completion)", function()
			local state = makeState({
				sequence = { 1, 2, 3 },
				gamePhase = "input",
				playerIndex = 0,
			})

			-- First correct input — round not complete
			state = gameReducer(state, { type = "CORRECT_INPUT" })
			assert.are.equal(0, state.score)
			assert.are.equal(1, state.playerIndex)

			-- Second correct input — still not complete
			state = gameReducer(state, { type = "CORRECT_INPUT" })
			assert.are.equal(0, state.score)
			assert.are.equal(2, state.playerIndex)
		end)

		it("scores on final input of the sequence", function()
			local state = makeState({
				sequence = { 1, 2, 3 },
				gamePhase = "input",
				playerIndex = 2,
				score = 0,
			})

			-- Third correct input — round complete
			state = gameReducer(state, { type = "CORRECT_INPUT" })
			assert.are.equal(1, state.score)
			assert.are.equal(3, state.playerIndex)
		end)

		it("ends game on wrong input", function()
			local state = makeState({
				sequence = { 1 },
				gamePhase = "input",
				playerIndex = 0,
			})

			state = gameReducer(state, { type = "WRONG_INPUT" })
			assert.are.equal("gameover", state.gamePhase)
		end)

		it("preserves score on game over", function()
			local state = makeState({
				sequence = { 1, 2 },
				gamePhase = "input",
				playerIndex = 0,
				score = 3,
				highScore = 5,
			})

			state = gameReducer(state, { type = "WRONG_INPUT" })
			assert.are.equal("gameover", state.gamePhase)
			assert.are.equal(3, state.score)
			assert.are.equal(5, state.highScore)
		end)
	end)

	describe("progressive difficulty", function()
		it("grows sequence after each successful round", function()
			-- Complete round 1 (sequence of 1)
			local state = makeState({
				sequence = { 2 },
				gamePhase = "input",
				playerIndex = 0,
			})
			state = gameReducer(state, { type = "CORRECT_INPUT" })
			assert.are.equal(1, state.score)

			-- Start next round
			state = gameReducer(state, { type = "NEXT_ROUND" })
			assert.are.equal(2, #state.sequence)
			assert.are.equal("showing", state.gamePhase)
			assert.are.equal(0, state.playerIndex)
		end)

		it("preserves existing sequence when growing", function()
			local state = makeState({
				sequence = { 1, 3 },
				gamePhase = "input",
				playerIndex = 1,
				score = 1,
			})
			-- Complete the round
			state = gameReducer(state, { type = "CORRECT_INPUT" })
			assert.are.equal(2, state.score)

			-- Next round
			state = gameReducer(state, { type = "NEXT_ROUND" })
			assert.are.equal(3, #state.sequence)
			assert.are.equal(1, state.sequence[1])
			assert.are.equal(3, state.sequence[2])
			-- Third element is random but valid
			assert.is_true(state.sequence[3] >= 1 and state.sequence[3] <= 4)
		end)

		it("does not mutate original sequence", function()
			local state = makeState({ sequence = { 1, 2 } })
			gameReducer(state, { type = "NEXT_ROUND" })
			assert.are.equal(2, #state.sequence)
		end)
	end)

	describe("scoring and high score", function()
		it("updates high score when score exceeds it", function()
			local state = makeState({
				sequence = { 1 },
				gamePhase = "input",
				playerIndex = 0,
				score = 5,
				highScore = 5,
			})

			state = gameReducer(state, { type = "CORRECT_INPUT" })
			assert.are.equal(6, state.score)
			assert.are.equal(6, state.highScore)
		end)

		it("does not lower high score when score is below it", function()
			local state = makeState({
				sequence = { 1 },
				gamePhase = "input",
				playerIndex = 0,
				score = 0,
				highScore = 10,
			})

			state = gameReducer(state, { type = "CORRECT_INPUT" })
			assert.are.equal(1, state.score)
			assert.are.equal(10, state.highScore)
		end)

		it("tracks high score across multiple games", function()
			-- Game 1: score 2 through two rounds
			local state = gameReducer(INITIAL_STATE, { type = "START_GAME" })
			-- Force known state for round 1
			state = makeState({
				highScore = state.highScore,
				score = 0,
				playerIndex = 0,
				sequence = { 1 },
			})
			state = gameReducer(state, { type = "CORRECT_INPUT" })
			assert.are.equal(1, state.score)
			assert.are.equal(1, state.highScore)

		-- Round 2: sequence now has 2 elements, set up so one input completes it
		state = gameReducer(state, { type = "NEXT_ROUND" })
		state = vim.tbl_extend("force", state, {
			gamePhase = "input",
			playerIndex = 1, -- last input of 2-element sequence
		})
		state = gameReducer(state, { type = "CORRECT_INPUT" })
		assert.are.equal(2, state.score)
		assert.are.equal(2, state.highScore)

			-- Game 2: score resets, high score persists
			state = gameReducer(state, { type = "START_GAME" })
			assert.are.equal(0, state.score)
			assert.are.equal(2, state.highScore)
		end)
	end)

	describe("full game flow", function()
		it("plays a complete game: start, score, game over, restart", function()
			-- Start game
			local state = gameReducer(INITIAL_STATE, { type = "START_GAME" })
			assert.are.equal("showing", state.gamePhase)
			assert.are.equal(1, #state.sequence)

			-- Simulate entering input phase (flash sequence done externally)
			state = vim.tbl_extend("force", state, { gamePhase = "input" })

			-- Correct input — round 1 complete
			state = gameReducer(state, { type = "CORRECT_INPUT" })
			assert.are.equal(1, state.score)

			-- Next round
			state = gameReducer(state, { type = "NEXT_ROUND" })
			assert.are.equal(2, #state.sequence)
			state = vim.tbl_extend("force", state, { gamePhase = "input" })

			-- Wrong input — game over
			state = gameReducer(state, { type = "WRONG_INPUT" })
			assert.are.equal("gameover", state.gamePhase)
			assert.are.equal(1, state.score)
			assert.are.equal(1, state.highScore)

			-- Restart
			state = gameReducer(state, { type = "START_GAME" })
			assert.are.equal("showing", state.gamePhase)
			assert.are.equal(0, state.score)
			assert.are.equal(1, state.highScore)
			assert.are.equal(1, #state.sequence)
		end)
	end)

	describe("unknown actions", function()
		it("returns state unchanged", function()
			local state = makeState()
			local new_state = gameReducer(state, { type = "NONEXISTENT" })
			assert.are.equal(state, new_state)
		end)
	end)
end)
