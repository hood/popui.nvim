local core = require("popui/core")

local formatEntries = function(entries)
    local formatItem = function(entry)
        return (entry.lnum or "?")
            .. ":"
            .. (entry.col or "?")
            .. " ["
            .. (entry.code or "?")
            .. "] "
            .. (entry.message and entry.message:gsub("\r?\n", " ") or "?")
    end

    local results = {}

    for index, entry in pairs(entries) do
        table.insert(results, string.format("%s", formatItem(entry)))
    end

    return results
end

local diagnosticsNavigator = function()
    local entries = vim.diagnostic.get(0)
    local originalWindowId = vim.api.nvim_get_current_win()

    if entries == nil or vim.tbl_isempty(entries) then
        return
    end

    core:spawnListPopup(
        "Diagnostics",
        formatEntries(entries),
        function(lineNumber, lineContent)
            vim.api.nvim_win_set_cursor(
                originalWindowId,
                { entries[lineNumber].lnum + 1, entries[lineNumber].col }
            )
        end,
        vim.g.popui_border_style
    )
end

return diagnosticsNavigator
