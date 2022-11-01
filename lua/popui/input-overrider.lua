local borders = require("popui/borders")
local core = require("popui/core")

local customUIInput = function(options, onConfirm)
	core:spawnInputPopup(options.default, function(lineNumber, lineContent)
		onConfirm(lineContent)
	end)
end

return customUIInput
