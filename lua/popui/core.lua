local Core = {}
Core._index = Core

Core.activeWindowId = nil
Core.activeBufferNumber = nil

Core.PopupTypes = {
	List = "list",
	Input = "input",
}

-- Get the size of the screen.
local function getNvimSize()
	local uis = vim.api.nvim_list_uis()

	local width = 0
	local height = 0

	for i = 1, #uis do
		width = width + uis[i].width
		height = height + uis[i].height
	end

	return width, height + vim.o.ch + 1
end

local getLongestEntry = function(entries)
	local result = 0

	for index, entry in pairs(entries) do
		if #entry > result then
			result = #entry
		end
	end

	return result
end

-- Calculate the position and size of the popup window, given the entries.
local function getListWindowConfiguration(entries)
	local width, height = getNvimSize()

	local popupWidth = entries and getLongestEntry(entries) + 5 or math.floor(width / 4)
	local popupHeight = entries and #entries or 1

	if popupHeight > height then
		error("unable to create the config, your window is too small, please zoom out")
	end

	if popupWidth > width then
		error("unable to create the config, your window is too small, please zoom out")
	end

	local currentCursorPosition = vim.api.nvim_win_get_cursor(0)

	return {
		relative = "win",
		win = 0,
		row = currentCursorPosition[1] - math.ceil(popupHeight / 2),
		col = currentCursorPosition[2] - math.ceil(popupWidth / 2),
		width = popupWidth,
		height = popupHeight,
		border = "rounded",
	}
end

-- Calculate the position and size of the popup window, given the initial text.
local function getInputWindowConfiguration(initialText)
	local width, height = getNvimSize()

	local popupWidth = 48 -- initialText and #initialText + #"Rename to: " or 16
	local popupHeight = 1

	if popupHeight > height then
		error("unable to create the config, your window is too small, please zoom out")
	end

	if popupWidth > width then
		error("unable to create the config, your window is too small, please zoom out")
	end

	local currentCursorPosition = vim.api.nvim_win_get_cursor(0)

	return {
		relative = "win",
		win = 0,
		row = currentCursorPosition[1] - math.ceil(popupHeight / 2),
		col = currentCursorPosition[2] - math.ceil(popupWidth / 2),
		width = popupWidth,
		height = popupHeight,
		border = "rounded",
	}
end

local function getTitleWindowConfiguration(mainWindowOptions)
	return {
		relative = "editor",
		win = 0,
		row = mainWindowOptions - 1,
		col = mainWindowOptions.col,
		width = mainWindowOptions.width,
		height = mainWindowOptions.height,
		border = "single",
	}
end

function Core:createBuffer(popupType)
	local bufferNumber = vim.api.nvim_create_buf(false, true)

	vim.bo[bufferNumber].modifiable = true
	vim.bo[bufferNumber].readonly = false
	vim.bo[bufferNumber].bufhidden = true
	vim.bo[bufferNumber].textwidth = 100

	return bufferNumber
end

function Core:createWindow(bufferNumber, shouldEnter, configuration)
	local shouldEnter = true

	local windowId = vim.api.nvim_open_win(bufferNumber, shouldEnter, configuration)

	vim.wo[windowId].rnu = false
	vim.wo[windowId].nu = false
	vim.wo[windowId].fillchars = "eob: "

	return windowId
end

function Core:setupKeymaps(popupBufferNumber, popupWindowId, keymaps)
	if vim.tbl_isempty(keymaps) then
		return
	end

	for key, callback in pairs(keymaps) do
		vim.api.nvim_buf_set_keymap(popupBufferNumber, "n", key, "", {
			noremap = true,
			silent = true,
			callback = function()
				print("normal callback invoked")

				local currentLineNumber = vim.api.nvim_win_get_cursor(popupWindowId)[1]
				local currentLineContent =
					vim.api.nvim_buf_get_lines(popupBufferNumber, currentLineNumber - 1, currentLineNumber, false)[1]

				callback(currentLineNumber, currentLineContent)
			end,
		})

		vim.api.nvim_buf_set_keymap(popupBufferNumber, "i", key, "", {
			noremap = true,
			silent = true,
			callback = function()
				print("insert callback invoked")

				local currentLineNumber = vim.api.nvim_win_get_cursor(popupWindowId)[1]
				local currentLineContent =
					vim.api.nvim_buf_get_lines(popupBufferNumber, currentLineNumber - 1, currentLineNumber, false)[1]

				callback(currentLineNumber, currentLineContent)
			end,
		})
	end
end

function Core:setupDefaultKeymaps(popupBufferNumber, popupWindowId)
	local keymaps = {
		-- ["<CR>"] = function(lineNumber, lineContent)
		-- 	vim.api.nvim_win_close(windowId, true)
		-- 	vim.api.nvim_set_current_buf(bufferNumber)
		-- 	vim.api.nvim_win_set_cursor(windowId, { lineNumber, 0 })
		-- end,
		["<Esc>"] = function()
			print("PRESSED ESC")
			self:closePopup(popupBufferNumber, popupWindowId)
		end,
		["<C-c>"] = function()
			self:closePopup(popupBufferNumber, popupWindowId)
		end,
		["<C-o>"] = function()
			self:closePopup(popupBufferNumber, popupWindowId)
		end,
	}

	self:setupKeymaps(popupBufferNumber, popupWindowId, keymaps)
end

function Core:spawnListPopup(bufferNumber, entries)
	-- Create the popup, calculating its size based on the entries.
	local windowId = self:createWindow(bufferNumber, true, getListWindowConfiguration(entries))

	-- TODO: Write title.
	-- Write entries into the popup.
	vim.api.nvim_buf_set_lines(bufferNumber, 0, -1, false, entries)

	-- Seal the popup.
	vim.api.nvim_buf_set_option(bufferNumber, "modifiable", false)
	vim.api.nvim_buf_set_option(bufferNumber, "readonly", true)

	-- Force buffer to normal mode
	-- vim.api.nvim_buf_set_option(bufferNumber, "buftype", "prompt")

	-- Set the cursor to the first line.
	vim.api.nvim_win_set_cursor(windowId, { 1, 0 })

	return windowId
end

function Core:spawnInputPopup(popupBufferNumber, initialText)
	-- Create the popup, calculating its size based on the entries.
	local popupWindowId = self:createWindow(popupBufferNumber, true, getInputWindowConfiguration(initialText))

	local prefix = "Rename to: "

	-- Make the popup an interactive prompt.
	vim.api.nvim_buf_set_option(popupBufferNumber, "modifiable", true)
	vim.api.nvim_buf_set_option(popupBufferNumber, "readonly", false)
	vim.api.nvim_buf_set_option(popupBufferNumber, "bufhidden", "hide")
	vim.api.nvim_buf_set_option(popupBufferNumber, "buftype", "prompt")
	vim.api.nvim_win_set_option(popupWindowId, "wrap", false)
	vim.api.nvim_win_set_option(popupWindowId, "number", false)
	vim.api.nvim_win_set_option(popupWindowId, "relativenumber", false)
	vim.fn.prompt_setprompt(popupBufferNumber, prefix)

	-- NOTE: Very important! If you're trying to set lines for a prompt buffer
	-- with a prefix, you have to set `prefix..initialText` and not just `initialText`,
	-- even if you had already set the prefix with `prompt_setprompt`.
	local lineToSet = prefix .. initialText
	local lineCount = vim.api.nvim_buf_line_count(popupBufferNumber)
	vim.api.nvim_buf_set_lines(popupBufferNumber, lineCount - 1, -1, false, { lineToSet })
	vim.cmd("startinsert!")

	return popupWindowId
end

-- TODO: Export generic and switch for specialized, or export specialized?
function Core:spawnPopup(popupType, entries, keymaps, initialText)
	local containerWindowId = vim.api.nvim_get_current_win()
	local popupBufferNumber = self:createBuffer(popupType)
	local popupWindowId = nil

	-- Handle LIST type popups.
	if popupType == self.PopupTypes.List then
		popupWindowId = self:spawnListPopup(popupBufferNumber, entries)
	-- Handle INPUT type popups.
	elseif popupType == self.PopupTypes.Input then
		popupWindowId = self:spawnInputPopup(popupBufferNumber, initialText)
	end

	-- TODO: Draw title in a single row window above the popup.

	if popupWindowId == nil then
		error("Unable to create the popup window.")
	end

	self.activeWindowId = popupWindowId
	self.activeBufferNumber = popupBufferNumber

	-- self:setupKeymaps(popupBufferNumber, popupWindowId, keymaps)
	self:setupDefaultKeymaps(popupBufferNumber, popupWindowId)
end

function Core:closePopup(popupBufferNumber, popupWindowId)
	vim.api.nvim_win_close(popupWindowId, true)
	vim.api.nvim_buf_delete(popupBufferNumber, { force = true })

	self.activeWindowId = nil
	self.activeBufferNumber = nil
end

-- This is intended for external usage only, we avoid using it internally.
function Core:closeActivePopup()
	if self.activeWindowId ~= nil and self.activeBufferNumber ~= nil then
		self:closePopup(self.activeBufferNumber, self.activeWindowId)
	end
end

return Core
