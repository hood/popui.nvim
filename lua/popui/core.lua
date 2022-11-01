local Core = {}
Core._index = Core

Core.activeWindowId = nil
Core.activeBufferNumber = nil
Core.activePopupType = nil

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
local function getListWindowConfiguration(entries, bordersType)
	local width, height = getNvimSize()

	local popupWidth = entries and getLongestEntry(entries) + 5 or math.floor(width / 4)
	local popupHeight = entries and #entries or 1

	if popupHeight > height then
		error("unable to create the config, your window is too small, please zoom out")
	end

	if popupWidth > width then
		error("unable to create the config, your window is too small, please zoom out")
	end

	return {
		relative = "cursor",
		row = 0,
		col = math.ceil(popupWidth / 2),
		width = popupWidth,
		height = popupHeight,
		anchor = "SE",
		border = bordersType == "sharp" and "single" or bordersType,
	}
end

-- Calculate the position and size of the popup window, given the initial text.
local function getInputWindowConfiguration(initialText, bordersType)
	local width, height = getNvimSize()

	local popupWidth = 48 -- initialText and #initialText + #"Rename to: " or 16
	local popupHeight = 1

	if popupHeight > height then
		error("unable to create the config, your window is too small, please zoom out")
	end

	if popupWidth > width then
		error("unable to create the config, your window is too small, please zoom out")
	end

	return {
		relative = "cursor",
		row = 0,
		col = math.ceil(popupWidth / 2),
		width = popupWidth,
		height = popupHeight,
		anchor = "SE",
		border = bordersType == "sharp" and "single" or bordersType,
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

	local modes = { "n", "v", "i" }

	for _, mode in pairs(modes) do
		for key, callback in pairs(keymaps) do
			vim.api.nvim_buf_set_keymap(popupBufferNumber, mode, key, "", {
				noremap = true,
				silent = true,
				callback = function()
					local currentLineNumber = vim.api.nvim_win_get_cursor(popupWindowId)[1]
					local currentLineContent = vim.api.nvim_buf_get_lines(
						popupBufferNumber,
						currentLineNumber - 1,
						currentLineNumber,
						false
					)[1]

					callback(currentLineNumber, currentLineContent)
				end,
			})
		end
	end
end

function Core:setupDefaultKeymaps(popupBufferNumber, popupWindowId)
	local keymaps = {
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

function Core:initializePopup(popupType)
	local popupBufferNumber = self:createBuffer(popupType)

	return popupBufferNumber
end

function Core:registerPopup(popupWindowId, popupBufferNumber, popupType)
	self.popupWindowId = popupWindowId
	self.popupBufferNumber = popupBufferNumber
	self.activePopupType = popupType
end

function Core:closePopup(popupBufferNumber, popupWindowId)
	vim.api.nvim_win_close(popupWindowId, true)
	vim.api.nvim_buf_delete(popupBufferNumber, { force = true })

	self.activeWindowId = nil
	self.activeBufferNumber = nil
	self.activePopupType = nil
end

-- This is intended for external usage only, we avoid using it internally.
function Core:closeActivePopup()
	if self.activeWindowId ~= nil and self.activeBufferNumber ~= nil then
		self:closePopup(self.activeBufferNumber, self.activeWindowId)
	end
end

function Core:spawnListPopup(entries, handleConfirm, bordersType)
	local popupBufferNumber = self:initializePopup(self.PopupTypes.List)

	-- Create the popup, calculating its size based on the entries.
	local popupWindowId = self:createWindow(popupBufferNumber, true, getListWindowConfiguration(entries, bordersType))

	-- Write entries into the popup.
	vim.api.nvim_buf_set_lines(popupBufferNumber, 0, -1, false, entries)

	-- Seal the popup.
	vim.api.nvim_buf_set_option(popupBufferNumber, "modifiable", false)
	vim.api.nvim_buf_set_option(popupBufferNumber, "readonly", true)

	-- Set the cursor to the first line.
	vim.api.nvim_win_set_cursor(popupWindowId, { 1, 0 })

	self:setupKeymaps(popupBufferNumber, popupWindowId, {
		["<Cr>"] = function(lineNumber, lineContent)
			handleConfirm(lineNumber, lineContent)
			self:closePopup(popupBufferNumber, popupWindowId)
		end,
	})
	self:setupDefaultKeymaps(popupBufferNumber, popupWindowId)
end

function Core:spawnInputPopup(initialText, handleConfirm, bordersType)
	local popupBufferNumber = self:initializePopup(self.PopupTypes.Input)

	-- Create the popup, calculating its size based on the entries.
	local popupWindowId =
		self:createWindow(popupBufferNumber, true, getInputWindowConfiguration(initialText, bordersType))

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
	local linesCount = vim.api.nvim_buf_line_count(popupBufferNumber)
	vim.api.nvim_buf_set_lines(popupBufferNumber, linesCount - 1, -1, false, { lineToSet })
	vim.cmd("startinsert!")

	self:setupKeymaps(popupBufferNumber, popupWindowId, {
		["<Cr>"] = function(lineNumber, lineContent)
			handleConfirm(lineNumber, lineContent:sub(#"Rename to: " + 1))
			self:closePopup(popupBufferNumber, popupWindowId)
		end,
	})
	self:setupDefaultKeymaps(popupBufferNumber, popupWindowId)
end

return Core
