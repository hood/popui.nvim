local popfix = require"popfix"

local popupReference = nil

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
    table.insert(results, string.format('%d: %s', index, formatItem(entry)))
  end

  return results
end

local customUISelect = function(entries, stuff, onUserChoice)
  assert(
    entries ~= nil and not vim.tbl_isempty(entries),
    "No entries available."
  )

  assert(
    popupReference == nil,
    "Busy in other LSP popup."
  )

  local commitChoice = function(choiceIndex)
    onUserChoice(entries[choiceIndex], choiceIndex)
  end

  local formattedEntries = formatEntries(entries, stuff.format_item)

  popupReference = popfix:new({
    width = calculatePopupWidth(formattedEntries),
    height = #formattedEntries,
    close_on_bufleave = true,
    keymaps = {
      i = {
        ['<Cr>'] = function(popup)
          popup:close(function(sel) commitChoice(sel) end)
        end
      },
      n = {
        ['<Cr>'] = function(popup)
          popup:close(function(sel) commitChoice(sel) end)
        end
      },
    },
    mode = 'cursor',
    list = {
      numbering = true,
      border = true
    },
    data = formattedEntries
  })
end

return customUISelect
