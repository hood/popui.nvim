local core = require("popui/core")

local marksManager = function()
    local marks = vim.fn.getmarklist()

    if #marks == 0 then
        print("No marks found.")
        return
    end

    local entries = core:formatEntries(core.WindowTypes.MarksManager, marks)

    if #entries == 0 then
        print("No uppercase marks found.")
        return
    end

    core:spawnListPopup(
        core.WindowTypes.MarksManager,
        "Marks",
        entries,
        function(lineNumber, _)
            vim.api.nvim_feedkeys(
                "`" .. marks[lineNumber].mark:gsub("'", ""),
                "n",
                false
            )
        end,
        vim.g.popui_border_style
    )
end

return marksManager
