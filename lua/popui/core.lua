local Core = {}
Core._index = Core

Core.activeWindowId = nil
Core.activeBufferNumber = nil
Core.activePopupType = nil
Core.activeTitleWindowId = nil
Core.activeTitleBufferNumber = nil

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

    local popupWidth = entries and getLongestEntry(entries) + 5
        or math.floor(width / 4)
    local popupHeight = entries and #entries or 1

    if popupHeight > height then
        error(
            "unable to create the config, your window is too small, please zoom out"
        )
    end

    if popupWidth > width then
        error(
            "unable to create the config, your window is too small, please zoom out"
        )
    end

    return {
        relative = "cursor",
        row = 0,
        col = math.ceil(popupWidth / 2),
        width = popupWidth,
        height = popupHeight,
        anchor = "SE",
        border = bordersType == "sharp" and "single" or bordersType or "single",
    }
end

-- Calculate the position and size of the popup window, given the initial text.
local function getInputWindowConfiguration(initialText, windowTitle, bordersType)
    local width, height = getNvimSize()


    local popupWidth = math.max(#(initialText or ""), #(windowTitle or "")) + 4
    local popupHeight = 1

    if popupHeight > height then
        error(
            "unable to create the config, your window is too small, please zoom out"
        )
    end

    if popupWidth > width then
        error(
            "unable to create the config, your window is too small, please zoom out"
        )
    end

    return {
        relative = "cursor",
        row = 0,
        col = math.ceil(popupWidth / 2),
        width = popupWidth,
        height = popupHeight,
        anchor = "SE",
        border = bordersType == "sharp" and "single" or bordersType or "single",
    }
end

function Core:addTitleToWindow(referenceWindowId, title)
    if not vim.api.nvim_win_is_valid(referenceWindowId) then
        return
    end

    -- HACK to force the parent window to position itself
    -- See https://github.com/neovim/neovim/issues/13403
    vim.cmd("redraw")

    local width = math.min(
        vim.api.nvim_win_get_width(referenceWindowId) - 4,
        2 + vim.api.nvim_strwidth(title)
    )

    local column =
        math.floor((vim.api.nvim_win_get_width(referenceWindowId) - width) / 2)

    local titleBufferNumber = vim.api.nvim_create_buf(false, true)

    local titleWindowId = vim.api.nvim_open_win(titleBufferNumber, false, {
        relative = "win",
        win = referenceWindowId,
        width = width,
        height = 1,
        row = -1,
        col = column,
        focusable = false,
        zindex = 151,
        style = "minimal",
        noautocmd = true,
    })

    vim.api.nvim_win_set_option(
        titleWindowId,
        "winblend",
        vim.api.nvim_win_get_option(referenceWindowId, "winblend")
    )

    vim.api.nvim_buf_set_option(titleBufferNumber, "bufhidden", "wipe")

    vim.api.nvim_buf_set_lines(
        titleBufferNumber,
        0,
        -1,
        true,
        { " " .. title .. " " }
    )

    return titleWindowId, titleBufferNumber
end

function Core:createBuffer()
    local bufferNumber = vim.api.nvim_create_buf(false, true)

    vim.bo[bufferNumber].modifiable = true
    vim.bo[bufferNumber].readonly = false
    vim.bo[bufferNumber].bufhidden = true
    vim.bo[bufferNumber].textwidth = 100

    return bufferNumber
end

function Core:createWindow(bufferNumber, configuration)
    local windowId = vim.api.nvim_open_win(bufferNumber, true, configuration)

    vim.wo[windowId].rnu = false
    vim.wo[windowId].number = false
    vim.wo[windowId].fillchars = "eob: "
    vim.wo[windowId].signcolumn = "no"

    return windowId
end

function Core:setupKeymaps(popupBufferNumber, popupWindowId, keymaps)
    if vim.tbl_isempty(keymaps) then
        return
    end

    for _, mode in pairs({ "n", "v", "i" }) do
        for key, callback in pairs(keymaps) do
            vim.api.nvim_buf_set_keymap(popupBufferNumber, mode, key, "", {
                noremap = true,
                silent = true,
                callback = function()
                    local currentLineNumber =
                        vim.api.nvim_win_get_cursor(popupWindowId)[1]
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
            self:closeActivePopup()
        end,
        ["<C-c>"] = function()
            self:closeActivePopup()
        end,
        ["<C-o>"] = function()
            self:closeActivePopup()
        end,
    }

    self:setupKeymaps(popupBufferNumber, popupWindowId, keymaps)
end

function Core:registerPopup(
    popupWindowId,
    popupBufferNumber,
    popupType,
    titleWindowId,
    titleBufferNumber
)
    self.activePopupWindowId = popupWindowId
    self.activePopupBufferNumber = popupBufferNumber
    self.activePopupType = popupType
    self.activeTitleWindowId = titleWindowId
    self.activeTitleBufferNumber = titleBufferNumber
end

-- Close window and delete buffer for a given popup.
function Core:wipePopup(windowId, bufferNumber)
    if windowId and vim.api.nvim_win_is_valid(windowId) then
        vim.api.nvim_win_close(windowId, true)
    end

    if bufferNumber and vim.api.nvim_buf_is_valid(bufferNumber) then
        vim.api.nvim_buf_delete(bufferNumber, { force = true })
    end
end

-- Closes the currently active popup and its title popup.
function Core:closeActivePopup()
    -- Clean the popup window and buffer.
    self:wipePopup(self.activePopupWindowId, self.activePopupBufferNumber)

    self.activePopupWindowId = nil
    self.activePopupBufferNumber = nil
    self.activePopupType = nil

    -- Clean the title window and buffer.
    self:wipePopup(self.activeTitleWindowId, self.activeTitleBufferNumber)

    self.activeTitleWindowId = nil
    self.activeTitleBufferNumber = nil
end

function Core:spawnListPopup(windowTitle, entries, handleConfirm, bordersType)
    local popupBufferNumber = self:createBuffer()

    -- Create the popup, calculating its size based on the entries.
    local popupWindowId = self:createWindow(
        popupBufferNumber,
        getListWindowConfiguration(entries, bordersType)
    )

    -- Write entries into the popup.
    vim.api.nvim_buf_set_lines(popupBufferNumber, 0, -1, false, entries)

    -- Seal the popup.
    vim.api.nvim_buf_set_option(popupBufferNumber, "modifiable", false)
    vim.api.nvim_buf_set_option(popupBufferNumber, "readonly", true)

    -- Set the cursor to the first line.
    vim.api.nvim_win_set_cursor(popupWindowId, { 1, 0 })

    local titleWindowId, titleBufferNumber =
        self:addTitleToWindow(popupWindowId, windowTitle)

    self:setupKeymaps(popupBufferNumber, popupWindowId, {
        ["<Cr>"] = function(lineNumber, lineContent)
            handleConfirm(lineNumber, lineContent)
            self:closeActivePopup()
        end,
    })
    self:setupDefaultKeymaps(popupBufferNumber, popupWindowId)

    self:registerPopup(
        popupWindowId,
        popupBufferNumber,
        self.PopupTypes.List,
        titleWindowId,
        titleBufferNumber
    )
end

function Core:spawnInputPopup(windowTitle, initialText, handleConfirm, bordersType)
    local popupBufferNumber = self:createBuffer()

    -- Create the popup, calculating its size based on the entries.
    local popupWindowId = self:createWindow(
        popupBufferNumber,
        getInputWindowConfiguration(initialText, windowTitle, bordersType)
    )

    local prefix = ">"

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
    local lineToSet = prefix .. (initialText or "")
    local linesCount = vim.api.nvim_buf_line_count(popupBufferNumber)
    vim.api.nvim_buf_set_lines(
        popupBufferNumber,
        linesCount - 1,
        -1,
        false,
        { lineToSet }
    )
    vim.cmd("startinsert!")

    local titleWindowId, titleBufferNumber =
        self:addTitleToWindow(popupWindowId, windowTitle)

    self:setupKeymaps(popupBufferNumber, popupWindowId, {
        ["<Cr>"] = function(lineNumber, lineContent)
            handleConfirm(lineNumber, lineContent:sub(#prefix + 1))
            self:closeActivePopup()
        end,
    })
    self:setupDefaultKeymaps(popupBufferNumber, popupWindowId)

    self:registerPopup(
        popupWindowId,
        popupBufferNumber,
        self.PopupTypes.List,
        titleWindowId,
        titleBufferNumber
    )
end

return Core
