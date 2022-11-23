local core = require("popui/core")

local customUIInput = function(options, onConfirm)
    core:spawnInputPopup(
        core.WindowTypes.InputOverrider,
        options.prompt or "Input",
        options.default,
        function(_, lineContent)
            onConfirm(lineContent)
        end,
        vim.g.popui_border_style
    )
end

return customUIInput
