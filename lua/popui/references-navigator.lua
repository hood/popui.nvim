local core = require("popui/core")

local referencesNavigator = function()
    local originalWindowId = vim.api.nvim_get_current_win()

    local parameters = vim.lsp.util.make_position_params(originalWindowId)
    parameters.context = { includeDeclaration = false }

    vim.lsp.buf_request(
        0,
        "textDocument/references",
        parameters,
        function(error, result, ctx, _)
            if error then
                print(error)
                return
            end

            if vim.tbl_isempty(result) then
                print("No references found.")
                return
            end

            local results = vim.lsp.util.locations_to_items(
                result,
                vim.lsp.get_active_clients()[1].offset_encoding
            )

            core:spawnListPopup(
                core.WindowTypes.ReferencesNavigator,
                "References",
                core:formatEntries(
                    core.WindowTypes.ReferencesNavigator,
                    results
                ),
                function(lineNumber, _)
                    vim.api.nvim_command(
                        "edit " .. results[lineNumber].filename
                    )

                    vim.api.nvim_set_current_win(originalWindowId)

                    vim.api.nvim_set_current_buf(
                        vim.fn.bufnr(results[lineNumber].filename)
                    )

                    vim.api.nvim_win_set_cursor(originalWindowId, {
                        results[lineNumber].lnum,
                        results[lineNumber].col - 1,
                    })
                end,
                vim.g.popui_border_style
            )
        end
    )
end

return referencesNavigator
