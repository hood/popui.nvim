TOTAL_REQUIRED_WIDTH = 32
TOTAL_REQUIRED_HEIGHT = 32
MAIN_WIDTH = 24
MAIN_HEIGHT = 10
STATUS_WIDTH = 24
STATUS_HEIGHT = 4

local function get_nvim_size()
    local uis = vim.api.nvim_list_uis()

    local width = 0
    local height = 0

    for i = 1, #uis do
        width = width + uis[i].width
        height = height + uis[i].height
    end

    return width, height + vim.o.ch + 1
end

local function get_window_config()
    local width, height = get_nvim_size()

    if TOTAL_REQUIRED_HEIGHT > height then
        error("unable to create the config, your window is too small, please zoom out")
    end

    if TOTAL_REQUIRED_WIDTH > width then
        error("unable to create the config, your window is too small, please zoom out")
    end

    local offset_row = math.ceil((height - MAIN_HEIGHT) / 2)
    local offset_col = math.floor((width - MAIN_WIDTH) / 2)

    local main = {
        relative = "win",
        win = container_win_id,
        row = offset_row,
        col = offset_col,
        width = MAIN_WIDTH,
        height = MAIN_HEIGHT,
        border = "single"
    }

    local status = {
        relative = "win",
        win = container_win_id,
        row = offset_row - 2,
        col = offset_col,
        width = STATUS_WIDTH,
        height = STATUS_HEIGHT,
    }

    return main, status
end

local function create_bufnr()
    -- controlling movement???
    local bufnr = vim.api.nvim_create_buf(false, true);

    vim.bo[bufnr].modifiable = true;
    vim.bo[bufnr].readonly = false;
    vim.bo[bufnr].bufhidden = true;

    return bufnr
end

local function create_window(bufnr, shouldEnter, configuration)  
  local shouldEnter = true

  local win_id = vim.api.nvim_open_win(bufnr, shouldEnter, configuration)

  vim.wo[win_id].rnu = false
  vim.wo[win_id].nu = false
  vim.wo[win_id].fillchars = 'eob: '

  return win_id
end

local stuff = function() 
  local fakeEntries = {
    "hello",
    "world",
    "this",
    "is",
    "a",
    "test",
  }
    
  local main, status = get_window_config()

  container_win_id = vim.api.nvim_get_current_win()

  mainBufferNumber = create_bufnr()
  mainWindowId = create_window(mainBufferNumber, true, main)

  -- statusBufferNumber = create_bufnr()
  -- statusWindowId = create_window(statusBufferNumber, false, status)
  --
  
  -- for INPUT popui just autostart in insert, and map esc and ctrl-c to close!

  vim.api.nvim_buf_set_keymap(
    mainBufferNumber, 
    'n', 
    '<CR>',
    '',
    { 
      noremap = true, 
      silent = true,
      callback = function() 
          local current_prompt = getCurrentLineContent(0)
          print('Hello -> ' .. current_prompt)
        end
    }
  )

  -- write stuff into mainwindow
  vim.api.nvim_buf_set_lines(mainBufferNumber, 0, -1, false, fakeEntries)
  
  -- set buffer to not modifiable
  vim.api.nvim_buf_set_option(mainBufferNumber, 'modifiable', false)
  vim.api.nvim_buf_set_option(mainBufferNumber, 'readonly', true)
end

function getCurrentLineNumber(windowId)
  return vim.api.nvim_win_get_cursor(windowId)[1]
end

function getCurrentLineContent(windowId)
  local currentLineNumber = getCurrentLineNumber(windowId)

  return vim.api.nvim_buf_get_lines(windowId, currentLineNumber - 1, currentLineNumber, false)[1]
end

function getCurrentLine()
    local lineNumber = getCurrentLineNumber()

    return vim.api.nvim_buf_get_lines(self.buffer, lineNumber - 1, lineNumber, false)[1]
end

local function setup_autocmds()
    local autocmd = vim.api.nvim_create_autocmd

    local PopuiAutocmds = vim.api.nvim_create_augroup('PopuiAutocmds', {})


-- READ: https://neovim.discourse.group/t/what-is-the-usual-way-of-disabling-built-in-commands-e-g-when-building-a-modal-dialog/2436
--


--     autocmd({"WinEnter"}, {
--         group = PopuiAutocmds,
--         pattern = "*",
--         callback = function()
--             if royale_open() then
--                 local win_id = vim.api.nvim_get_current_win()
--                 if win_id ~= main_win_id then
--                     vim.api.nvim_set_current_win(main_win_id)
--                 end
--             end
--         end
--     })

--     autocmd({"WinClosed"}, {
--         group = PopuiAutocmds,
--         pattern = "*",
--         callback = function()
--             if main_win_id ~= -1 then
--                 close_all()
--             end
--         end
--     })

--     autocmd({"VimResized"}, {
--         group = PopuiAutocmds,
--         pattern = "*",
--         callback = function()
--             vim.schedule(function()
--                 if royale_open() then
--                     royale_windows()
--                 end
--             end)
--         end
--     })

end

return stuff

--[[
-- TODO: NOTIONAIE
--
   Parameters:  
      • {buffer}  Buffer to display, or 0 for current buffer
      • {enter}   Enter the window (make it the current window)
      • {config}  Map defining the window configuration. Keys:
                  • relative: Sets the window layout to "floating", placed at
                    (row,col) coordinates relative to:
                    • "editor" The global editor grid
                    • "win" Window given by the `win` field, or current
                      window.
                    • "cursor" Cursor position in current window.

                  • win: |window-ID| for relative="win".
                  • anchor: Decides which corner of the float to place at
                    (row,col):
                    • "NW" northwest (default)
                    • "NE" northeast
                    • "SW" southwest
                    • "SE" southeast

                  • width: Window width (in character cells). Minimum of 1.
                  • height: Window height (in character cells). Minimum of 1.
                  • bufpos: Places float relative to buffer text (only when
                    relative="win"). Takes a tuple of zero-indexed [line,
                    column]. `row` and `col` if given are applied relative to this position, else they
                    default to:
                    • `row=1` and `col=0` if `anchor` is "NW" or "NE"
                    • `row=0` and `col=0` if `anchor` is "SW" or "SE" (thus
                      like a tooltip near the buffer text).

                  • row: Row position in units of "screen cell height", may be
                    fractional.
                  • col: Column position in units of "screen cell width", may
                    be fractional.
                  • focusable: Enable focus by user actions (wincmds, mouse
                    events). Defaults to true. Non-focusable windows can be
                    entered by |nvim_set_current_win()|.
                  • external: GUI should display the window as an external
                    top-level window. Currently accepts no other positioning
                    configuration together with this.
                  • zindex: Stacking order. floats with higher `zindex` go on top on floats with lower indices. Must be larger
                    than zero. The following screen elements have hard-coded
                    z-indices:
                    • 100: insert completion popupmenu
                    • 200: message scrollback
                    • 250: cmdline completion popupmenu (when
                      wildoptions+=pum) The default value for floats are 50.
                      In general, values below 100 are recommended, unless
                      there is a good reason to overshadow builtin elements.

                  • style: Configure the appearance of the window. Currently
                    only takes one non-empty value:
                    • "minimal" Nvim will display the window with many UI
                      options disabled. This is useful when displaying a
                      temporary float where the text should not be edited.
                      Disables 'number', 'relativenumber', 'cursorline',
                      'cursorcolumn', 'foldcolumn', 'spell' and 'list'
                      options. 'signcolumn' is changed to `auto` and
                      'colorcolumn' is cleared. The end-of-buffer region is
                      hidden by setting `eob` flag of 'fillchars' to a space
                      char, and clearing the |hl-EndOfBuffer| region in
                      'winhighlight'.

                  • border: Style of (optional) window border. This can either
                    be a string or an array. The string values are
                    • "none": No border (default).
                    • "single": A single line box.
                    • "double": A double line box.
                    • "rounded": Like "single", but with rounded corners ("╭"
                      etc.).
                    • "solid": Adds padding by a single whitespace cell.
                    • "shadow": A drop shadow effect by blending with the
                      background.
                    • If it is an array, it should have a length of eight or
                      any divisor of eight. The array will specifify the eight
                      chars building up the border in a clockwise fashion
                      starting with the top-left corner. As an example, the
                      double box style could be specified as [ "╔", "═" ,"╗",
                      "║", "╝", "═", "╚", "║" ]. If the number of chars are
                      less than eight, they will be repeated. Thus an ASCII
                      border could be specified as [ "/", "-", "\\", "|" ], or
                      all chars the same as [ "x" ]. An empty string can be
                      used to turn off a specific border, for instance, [ "",
                      "", "", ">", "", "", "", "<" ] will only make vertical
                      borders but not horizontal ones. By default,
                      `FloatBorder` highlight is used, which links to
                      `WinSeparator` when not defined. It could also be
                      specified by character: [ {"+", "MyCorner"}, {"x",
                      "MyBorder"} ].

                  • noautocmd: If true then no buffer-related autocommand
                    events such as |BufEnter|, |BufLeave| or |BufWinEnter| may
                    fire from calling this function.

    Return:  
        Window handle, or 0 on error
]]--
