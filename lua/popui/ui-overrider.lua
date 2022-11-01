local core = require("popui/core")

local formatEntries = function(entries, formatter)
	local formatItem = formatter or tostring

	local results = {}

	for index, entry in pairs(entries) do
		table.insert(results, string.format("%s", formatItem(entry)))
	end

	return results
end

local customUISelect = function(entries, stuff, onUserChoice)
	assert(entries ~= nil and not vim.tbl_isempty(entries), "No entries available.")

	core:spawnListPopup(formatEntries(entries, stuff.format_item), function(lineNumber, lineContent)
		onUserChoice(entries[lineNumber], lineNumber)
	end, vim.g.popui_border_style)
end

return customUISelect
