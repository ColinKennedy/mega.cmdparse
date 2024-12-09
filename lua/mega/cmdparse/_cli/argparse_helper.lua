--- Make dealing with COMMAND mode parsed arguments a bit easier.
---
---@module 'mega.cmdparse._cli.argparse_helper'
---

local argparse = require("mega.cmdparse._cli.argparse")
local tabler = require("mega.cmdparse._core.tabler")

local M = {}

--- Strip position `argument` up to the `column` offset.
---
---@param argument argparse.Argument A position argument, e.g. `foo`, to crop.
---@param column number A 1-or-more value to (basicall) lstrip by. e.g. `2`.
---@return argparse.Argument # The cropped argument. e.g. `fo`.
---
local function _make_left_cropped_position(argument, column)
    local value = argument.value
    ---@cast value string
    local cropped_value = string.sub(value, 1, argument.range.end_column - column)

    local copy = vim.deepcopy(argument)
    copy.range.end_column = column
    copy.value = cropped_value

    return copy
end

--- Remove the starting `index` arguments from `results`.
---
--- This function is useful for handling "subcommand triage".
---
---@param results argparse.Results
---    The parsed arguments + any remainder text.
---@param index number
---    A 1-or-more value. 1 has not effect. 2-or-more will start removing
---    arguments from the left-hand side of `results`.
---
function M.lstrip_arguments(results, index)
    local copy = vim.tbl_deep_extend("force", {}, results)
    local arguments = tabler.get_slice(results.arguments, index)
    copy.arguments = arguments

    return copy
end

--- Remove the ending `index` arguments from `results`.
---
--- This function is useful for handling "subcommand triage".
---
---@param results argparse.Results
---    The parsed arguments + any remainder text.
---@param column number
---    A 1-or-more value to (basicall) lstrip by. e.g. `2`.
---@return argparse.Results
---    The stripped copy from `results`.
---
function M.rstrip_arguments(results, column)
    ---@type argparse.Argument[]
    local arguments = {}

    if not vim.tbl_isempty(results.arguments) then
        local count = results.arguments
        local whole_arguments = tabler.get_slice(results.arguments, 1, #count - 1)

        for _, argument in ipairs(whole_arguments) do
            if argument.range.end_column > column then
                break
            end

            table.insert(arguments, argument)
        end

        local last = results.arguments[#count]

        if last.range.end_column <= column then
            table.insert(arguments, last)
        elseif last.argument_type == argparse.ArgumentType.position then
            table.insert(arguments, _make_left_cropped_position(last, column))
        end
    end

    local copy = vim.deepcopy(results)
    copy.arguments = arguments

    return copy
end

return M
