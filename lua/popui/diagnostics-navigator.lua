local popfix = require"popfix"
local borders = require"popui/borders"

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

local formatEntries = function(entries)
  local formatItem = function(entry) 
      return (entry.row or '?') .. ':' .. (entry.col or '?') .. ' [' .. (entry.code or '?') .. '] ' .. (entry.message or '?')
    end

  local results = {}

  for index, entry in pairs(entries) do
    table.insert(results, string.format('%s', formatItem(entry)))
  end

  return results
end

local diagnosticsNavigator = function()
  local entries = vim.diagnostic.get(0)

  if (entries == nil or vim.tbl_isempty(entries)) then
    return
  end

  assert(
    popupReference == nil,
    "Busy in other LSP popup."
  )

  local commitChoice = function(choiceIndex)
    vim.api.nvim_win_set_cursor(0, { entries[choiceIndex].row, entries[choiceIndex].col })
  end

  local formattedEntries = formatEntries(entries)

  popupReference = popfix:new({
    width = calculatePopupWidth(formattedEntries),
    height = #formattedEntries,
    close_on_bufleave = true,
    keymaps = {
      i = {
        ['<Cr>'] = function(popup)
          popup:close(function(sel) commitChoice(sel) end)
          popupReference = nil
        end
      },
      n = {
        ['<Cr>'] = function(popup)
          popup:close(function(sel) commitChoice(sel) end)
          popupReference = nil
        end,
        ['<C-o>'] = function(popup)
          popup:close()
          popupReference = nil
        end,
        ['<C-c>'] = function(popup)
          popup:close()
          popupReference = nil
        end,
        ['<Esc>'] = function(popup)
          popup:close()
          popupReference = nil
        end
      },
    },
    callbacks = {
      close = function() 
        popupReference = nil
      end
    },
    mode = 'cursor',
    list = {
      numbering = true,
      border = true,
      border_chars = borders[vim.g.popui_border_style or "rounded"],
    },
    data = formattedEntries
  })
end

return diagnosticsNavigator
