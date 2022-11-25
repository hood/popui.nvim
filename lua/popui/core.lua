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

Core.WindowTypes = {
    CodeAction = "code-action",
    DiagnosticsNavigator = "diagnostics-navigator",
    InputOverrider = "input-overrider",
    MarksManager = "marks-manager",
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

    for _, entry in pairs(entries) do
        if #entry > result then
            result = #entry
        end
    end

    return result
end

-- Checks whether the popup window fits in the current window.
local function validatePopupSize(popupWidth, popupHeight)
    local width, height = getNvimSize()

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
end

-- Calculate the position and size of the popup window, given the entries.
local function getListWindowConfiguration(entries, bordersType)
    local popupWidth = entries and getLongestEntry(entries) or 8
    local popupHeight = entries and #entries or 1

    validatePopupSize(popupWidth, popupHeight)

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
local function getInputWindowConfiguration(
    initialText,
    windowTitle,
    bordersType
)
    local popupWidth = math.max(#(initialText or ""), #(windowTitle or "")) + 4
    local popupHeight = 1

    validatePopupSize(popupWidth, popupHeight)

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

    -- Hack to force the parent window to position itself.
    -- (See https://github.com/neovim/neovim/issues/13403)
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

function Core:setupDefaultKeymaps(
    popupBufferNumber,
    popupWindowId,
    handleConfirm
)
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
        ["<Cr>"] = function(lineNumber, lineContent)
            handleConfirm(lineNumber, lineContent)
            self:closeActivePopup()
        end,
    }

    self:setupKeymaps(popupBufferNumber, popupWindowId, keymaps)
end

function Core:setupSpecificKeymaps(
    popupBufferNumber,
    popupWindowId,
    windowType,
    -- Cached arguments are needed to respawn a popup with the same arguments
    -- used to create it.
    cachedArguments
)
    local keymaps = {}

    if windowType == self.WindowTypes.MarksManager then
        local removeMark = function(_, lineContent)
            vim.api.nvim_del_mark(vim.split(lineContent, "\t")[1])

            vim.cmd("wviminfo!")
            vim.cmd("wshada!")

            self:closeActivePopup()

            -- Recalculate marks.
            local marks = vim.fn.getmarklist()

            if #marks == 0 then
                return
            end

            local entries =
                self:formatEntries(self.WindowTypes.MarksManager, marks)

            if #entries == 0 then
                return
            end

            self:spawnListPopup(
                self.WindowTypes.MarksManager,
                cachedArguments.windowTitle,
                entries,
                cachedArguments.handleConfirm,
                cachedArguments.bordersType
            )
        end

        keymaps = {
            ["x"] = removeMark,
            ["d"] = removeMark,
        }
    elseif windowType == self.WindowTypes.InputOverrider then
        self:setupKeymaps(popupBufferNumber, popupWindowId, {
            ["<C-w>"] = function(_, _)
                -- Delete the content (not the prefix) of th prompt buffer.
                vim.api.nvim_buf_set_lines(
                    popupBufferNumber,
                    0,
                    -1,
                    false,
                    { "" }
                )
            end,
            -- Override the default `<Cr>` keymap to handle the prefix used in
            -- input popups.
            ["<Cr>"] = function(lineNumber, lineContent)
                cachedArguments.handleConfirm(
                    lineNumber,
                    lineContent:sub(#cachedArguments.prefix + 1)
                )
                self:closeActivePopup()
            end,
        })
    end

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

function Core:highlightPopupEntries(windowType, popupBufferNumber, entries)
    if vim.fn.hlexists("PopuiCoordinates") == 0 then
        vim.cmd("highlight PopuiCoordinates ctermfg=Red guifg=#AA99CC")
    end

    if vim.fn.hlexists("PopuiDiagnosticsCodes") == 0 then
        vim.cmd("highlight PopuiDiagnosticsCodes ctermfg=Yellow guifg=#BBAA77")
    end

    if windowType == "marks-manager" then
        for i = 0, #entries - 1 do
            vim.api.nvim_buf_add_highlight(
                popupBufferNumber,
                -1,
                "PopuiCoordinates",
                i,
                0,
                vim.fn.strchars(entries[i + 1]:match("^[^\t]+"))
            )
        end
    elseif windowType == "diagnostics-navigator" then
        for i = 0, #entries - 1 do
            vim.api.nvim_buf_add_highlight(
                popupBufferNumber,
                -1,
                "PopuiCoordinates",
                i,
                0,
                vim.fn.strchars(entries[i + 1]:match("^[^\t]+"))
            )

            vim.api.nvim_buf_add_highlight(
                popupBufferNumber,
                -1,
                "PopuiDiagnosticsCodes",
                i,
                vim.fn.strchars(entries[i + 1]:match("^[^\t]+")) + 1,
                vim.fn.strchars(entries[i + 1]:match("^[^\t]+\t[^\t]+"))
            )
        end
    end
end

function Core:spawnListPopup(
    windowType,
    windowTitle,
    entries,
    handleConfirm,
    bordersType
)
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

    self:setupDefaultKeymaps(popupBufferNumber, popupWindowId, handleConfirm)
    self:setupSpecificKeymaps(popupBufferNumber, popupWindowId, windowType, {
        windowTitle = windowTitle,
        handleConfirm = handleConfirm,
        bordersType = bordersType,
    })

    self:highlightPopupEntries(windowType, popupBufferNumber, entries)

    self:registerPopup(
        popupWindowId,
        popupBufferNumber,
        self.PopupTypes.List,
        titleWindowId,
        titleBufferNumber
    )
end

function Core:spawnInputPopup(
    windowType,
    windowTitle,
    initialText,
    handleConfirm,
    bordersType
)
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

    self:setupDefaultKeymaps(popupBufferNumber, popupWindowId)
    self:setupSpecificKeymaps(popupBufferNumber, popupWindowId, windowType, {
        windowTitle = windowTitle,
        handleConfirm = handleConfirm,
        bordersType = bordersType,
        prefix = prefix,
    })

    self:registerPopup(
        popupWindowId,
        popupBufferNumber,
        self.PopupTypes.List,
        titleWindowId,
        titleBufferNumber
    )
end

function Core:formatEntries(windowType, entries, formatter)
    local results = {}

    -- Code action
    if windowType == self.WindowTypes.CodeAction then
        local formatItem = formatter or tostring

        for _, entry in pairs(entries) do
            table.insert(results, string.format("%s", formatItem(entry)))
        end
    -- Diagnostics navigator
    elseif windowType == self.WindowTypes.DiagnosticsNavigator then
        local formatItem = function(entry)
            return (entry.lnum or "?")
                .. ":"
                .. (entry.col or "?")
                .. "\t"
                .. "["
                .. (entry.code or "?")
                .. "]"
                .. "\t"
                .. (entry.message and entry.message:gsub("\r?\n", " ") or "?")
        end

        for _, entry in pairs(entries) do
            table.insert(results, string.format("%s", formatItem(entry)))
        end
    -- Marks manager
    elseif windowType == self.WindowTypes.MarksManager then
        for _, mark in pairs(entries) do
            local pathSegments = vim.split(mark.file, "/")

            local markSign = mark.mark:gsub("'", "")

            -- Ignore number marks, since they're created and persisted when
            -- exiting NeoVim and are not part of our main use-case.
            -- (ref.: https://neovim.io/doc/user/starting.html#shada).
            if tonumber(markSign, 10) == nil then
                results[#results + 1] = markSign
                    .. "\t"
                    .. pathSegments[#pathSegments - 1]
                    .. "/"
                    .. pathSegments[#pathSegments]
            end
        end
    end

    return results
end

return Core
