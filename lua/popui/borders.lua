local M = {}

M.sharp = {
	TOP_LEFT = '┌',
	TOP_RIGHT = '┐',
	MID_HORIZONTAL = '─',
	MID_VERTICAL = '│',
	BOTTOM_LEFT = '└',
	BOTTOM_RIGHT = '┘',
}

M.rounded = {
	TOP_LEFT = '╭',
	TOP_RIGHT = '╮',
	MID_HORIZONTAL = '─',
	MID_VERTICAL = '│',
	BOTTOM_LEFT = '╰',
	BOTTOM_RIGHT = '╯',
}

M.double = {
	TOP_LEFT = '╔',
	TOP_RIGHT = '╗',
	MID_HORIZONTAL = '═',
	MID_VERTICAL = '║',
	BOTTOM_LEFT = '╚',
	BOTTOM_RIGHT = '╝',
}

return M
