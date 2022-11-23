local core = require("popui/core")

local diagnosticsNavigator = function()
    local entries = vim.diagnostic.get(0)
    local originalWindowId = vim.api.nvim_get_current_win()

    if entries == nil or vim.tbl_isempty(entries) then
        return
    end

    core:spawnListPopup(
        core.WindowTypes.DiagnosticsNavigator,
        "Diagnostics",
        core:formatEntries(core.WindowTypes.DiagnosticsNavigator, entries),
        function(lineNumber, _)
            vim.api.nvim_win_set_cursor(
                originalWindowId,
                { entries[lineNumber].lnum + 1, entries[lineNumber].col }
            )
        end,
        vim.g.popui_border_style
    )
end

return diagnosticsNavigator
