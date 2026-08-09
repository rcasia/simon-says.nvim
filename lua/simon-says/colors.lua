--- Color constants for Simon Says game.
--- @module simon-says.colors

local M = {}

--- Color pairs: dark (inactive) and bright (lit/flash)
--- @type table<string, {dark: string, bright: string}>
M.COLORS = {
	GREEN = { dark = "#2d5a2d", bright = "#4ade80" },
	RED = { dark = "#5a2d2d", bright = "#f87171" },
	YELLOW = { dark = "#5a5a2d", bright = "#facc15" },
	BLUE = { dark = "#2d2d5a", bright = "#60a5fa" },
}

--- Canonical Simon color names in position order:
--- Top-left: GREEN (1), Top-right: RED (2)
--- Bottom-left: YELLOW (3), Bottom-right: BLUE (4)
M.COLOR_NAMES = { "GREEN", "RED", "YELLOW", "BLUE" }

--- Color values indexed by position (1-4)
M.COLOR_VALUES = {
	M.COLORS.GREEN,
	M.COLORS.RED,
	M.COLORS.YELLOW,
	M.COLORS.BLUE,
}

--- Inactive quadrant colors (dark)
M.DARK = {
	GREEN = M.COLORS.GREEN.dark,
	RED = M.COLORS.RED.dark,
	YELLOW = M.COLORS.YELLOW.dark,
	BLUE = M.COLORS.BLUE.dark,
}

--- Active/flash quadrant colors (bright)
M.LIT = {
	GREEN = M.COLORS.GREEN.bright,
	RED = M.COLORS.RED.bright,
	YELLOW = M.COLORS.YELLOW.bright,
	BLUE = M.COLORS.BLUE.bright,
}

--- UI colors
M.BORDER_COLOR = "#586572"
M.TEXT_COLOR = "#f8f9fa"
M.ACCENT_COLOR = "#FFD700"
M.DIM_COLOR = "#6c757d"

return M
