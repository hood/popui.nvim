local core = require("popui/core")

local customUISelect = function(entries, stuff, onUserChoice)
    assert(
        entries ~= nil and not vim.tbl_isempty(entries),
        "No entries available."
    )

    core:spawnListPopup(
        core.WindowTypes.CodeAction,
        stuff.prompt or "Options",
        core:formatEntries(
            core.WindowTypes.CodeAction,
            entries,
            stuff.format_item
        ),
        function(lineNumber, _)
            onUserChoice(entries[lineNumber], lineNumber)
        end,
        vim.g.popui_border_style
    )
end

return customUISelect
