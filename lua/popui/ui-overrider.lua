local popfix = require("popfix")
local borders = require("popui/borders")
local core = require("popui/core")

local calculatePopupWidth = function(entries)
	local result = 0

	for index, entry in pairs(entries) do
		if #entry > result then
			result = #entry
		end
	end

	return result + 5
end

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

	local commitChoice = function(choiceIndex)
		onUserChoice(entries[choiceIndex], choiceIndex)
	end

	local formattedEntries = formatEntries(entries, stuff.format_item)

	local coso = core:spawnPopup(core.PopupTypes.List, formattedEntries, {
		["<Cr>"] = function(lineNumber, lineContent)
			commitChoice(lineNumber)
			core:closeActivePopup()
		end,
	})
end

return customUISelect
