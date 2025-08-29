--- Make sure "Command API related" functionality works.

local cmdparse = require("mega.cmdparse")

--- Select line `start` to `end_` (inclusive), for `buffer`.
---
---@param start integer The first line to select. A 1-or-more value.
---@param end_ integer The last line to select, inclusive. A 1-or-more value.
---@param buffer integer? The buffer to affect (if none given, the current buffer is used).
---
local function _select_range(start, end_, buffer)
    buffer = buffer or vim.api.nvim_current_buf()
    vim.api.nvim_buf_set_mark(buffer, "<", start, 0, {})
    vim.api.nvim_buf_set_mark(buffer, ">", end_, 0, {})
    vim.cmd("normal! `<V`>")
end

describe("command", function()
    describe("vim argument", function()
        it("passes vim command information", function()
            local parser = cmdparse.ParameterParser.new({ name = "Test", help = "Test" })
            ---@type vim.api.keyset.create_user_command.command_args?
            local options = nil
            parser:set_execute(function(data)
                options = data.options
            end)

            cmdparse.create_user_command(parser, nil, { range = true })

            local buffer = vim.api.nvim_create_buf(false, true)

            local lines = {
                "This is line 1",
                "This is line 2",
                "This is line 3",
                "This is line 4",
                "This is line 5",
                "This is line 6",
                "This is line 7",
                "This is line 8",
            }

            vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
            vim.api.nvim_set_current_buf(buffer)
            _select_range(3, 7, buffer)

            vim.cmd([['<,'>Test]])

            -- NOTE: By the time `Test` runs, we should have the data we need
            ---@cast options vim.api.keyset.create_user_command.command_args

            assert.equal(3, options.line1)
            assert.equal(7, options.line2)
            assert.equal(-1, options.smods.verbose)
        end)
    end)
end)
