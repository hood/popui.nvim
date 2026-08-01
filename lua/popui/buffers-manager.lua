local core = require("popui/core")

local buffersManager = function()
    local originalWindowId = vim.api.nvim_get_current_win()

    local buffers = vim.fn.getbufinfo({ buflisted = 1 })

    if #buffers == 0 then
        print("No open buffers found.")
        return
    end

    core:spawnListPopup(
        core.WindowTypes.BuffersManager,
        "Buffers",
        core:formatEntries(core.WindowTypes.BuffersManager, buffers),
        -- `<Cr>` is handled by the buffers manager keymaps, which resolve the
        -- highlighted line against an up-to-date buffers list.
        nil,
        vim.g.popui_border_style,
        { buffers = buffers, originalWindowId = originalWindowId }
    )
end

return buffersManager
