--- Match exact / partial text of cmdparse parameters and argparse arguments.

local argparse = require("mega.cmdparse._cli.argparse")
local constant = require("mega.cmdparse._cli.cmdparse.constant")
local iterator_helper = require("mega.cmdparse._cli.cmdparse.iterator_helper")
local text_parse = require("mega.cmdparse._cli.cmdparse.text_parse")
local texter = require("mega.cmdparse._core.texter")
local logging = require("mega.logging")

local M = {}

local _LOGGER = logging.get_logger("mega.cmdparse._cli.cmdparse.matcher")

--- Remove whitespace from `text` but only if `text` is 100% whitespace.
---
---@param text string Some text to possibly strip.
---@return string # The processed `text` or, if it contains whitespace, the original `text`.
---
local function _remove_contiguous_whitespace(text)
    return (text:gsub("^%s*$", ""))
end

--- Get all auto-completions that `parser` is currently allowed to recommend.
---
--- All exhausted child parameters are excluded from the output.
---
---@param parser mega.cmdparse.ParameterParser
---    A parser to query.
---@param options mega.cmdparse._core.DisplayOptions?
---    Control minor behaviors of this function. e.g. What data to show.
---@return string[]
---    The found auto-completion results, if any.
---
function M.get_current_parser_completions(parser, options)
    ---@type string[]
    local output = {}

    -- NOTE: Get all possible initial arguments (check all parameters / subparsers)
    if parser:is_satisfied() then
        vim.list_extend(output, vim.fn.sort(M.get_matching_subparser_names("", parser)))
    end

    vim.list_extend(output, M.get_matching_position_parameters("", parser:get_position_parameters()))

    vim.list_extend(
        output,
        M.get_matching_partial_flag_text(
            "",
            parser:get_flag_parameters(),
            nil,
            { constant.ChoiceContext.auto_completing },
            options
        )
    )

    return output
end

--- Find all Argments starting with `prefix`.
---
---@param parameter mega.cmdparse.Parameter
---    The position, flag, or named parameter to consider nargs / choices / etc.
---@param argument argparse.Argument
---    A user's actual CLI input. It must either match `parameter` or be
---    a valid input to `parameter`. Or be the next valid parameter that would
---    normally follow `parameter`.
---@param parser mega.cmdparse.ParameterParser
---    The starting point to search within.
---@param contexts mega.cmdparse.ChoiceContext[]
---    A description of how / when this function is called. It gets passed to
---    `cmdparse.Parameter.choices()`.
---@param options mega.cmdparse._core.DisplayOptions
---    Control minor behaviors of this function. e.g. What data to show.
---@return string[] # The matching names, if any.
---
function M.get_exact_or_partial_matches(parameter, argument, parser, contexts, options)
    ---@type string[]
    local output = {}

    local prefix = text_parse.get_argument_name(argument)

    local matches = texter.get_array_startswith(parameter.names, prefix)

    if not vim.tbl_isempty(matches) and argument.value == false then
        if parameter:is_exhausted() then
            return {}
        end

        local nargs = parameter:get_nargs()

        if nargs == 1 then
            return { matches[1] .. "=" }
        end
    end

    prefix = text_parse.get_argument_value_text(argument)

    if argument.argument_type == argparse.ArgumentType.position and parameter.choices then
        ---@type string[]
        local choices = {}

        for _, text in ipairs(parameter.choices({ current_value = prefix, contexts = contexts })) do
            table.insert(choices, text_parse.escape_argument(text))
        end

        return choices
    end

    local value = argument.value or nil
    ---@cast value string

    prefix = text_parse.get_argument_name(argument)
    vim.list_extend(output, M.get_matching_position_parameters(prefix, parser:get_position_parameters(), contexts))
    vim.list_extend(
        output,
        M.get_matching_partial_flag_text(prefix, parser:get_flag_parameters(), value, contexts, options)
    )

    return output
end

--- Create auto-complete text for `parameter`, given some `value`.
---
---@param parameter mega.cmdparse.Parameter
---    A parameter that (we assume) takes exactly one value that we need
---    auto-completion options for.
---@param value string
---    The user-provided (exact or partial) value for the flag / named argument
---    value, if any. e.g. the `"bar"` part of `"--foo=bar"`.
---@param contexts mega.cmdparse.ChoiceContext[]?
---    A description of how / when this function is called. It gets passed to
---    `mega.cmdparse.Parameter.choices()`.
---@return string[]
---    All auto-complete values, if any.
---
local function _get_single_choices_text(parameter, value, contexts)
    if not parameter.choices then
        return { parameter.names[1] .. "=" }
    end

    contexts = contexts or {}

    ---@type string[]
    local output = {}

    for _, choice in
        ipairs(parameter.choices({
            contexts = vim.list_extend({ constant.ChoiceContext.value_matching }, contexts),
            current_value = value,
        }))
    do
        table.insert(output, parameter.names[1] .. "=" .. text_parse.escape_argument(choice))
    end

    return output
end

--- Find the child parser that matches `name`.
---
---@param name string The name of a child parser within `parser`.
---@param parser mega.cmdparse.ParameterParser The parent parser to search within.
---@return mega.cmdparse.ParameterParser? # The matching child parser, if any.
---
function M.get_exact_subparser_child(name, parser)
    for child_parser in iterator_helper.iter_parsers(parser) do
        if vim.tbl_contains(child_parser:get_names(), name) then
            return child_parser
        end
    end

    return nil
end

--- Check all `flags` that match `prefix` and `value`.
---
---@param prefix string
---    The name of the flag that must match, exactly or partially.
---@param flags mega.cmdparse.Parameter[]
---    All position / flag / named parameters.
---@param value string?
---    The user-provided (exact or partial) value for the flag / named argument
---    value, if any. e.g. the `"bar"` part of `"--foo=bar"`.
---@param contexts mega.cmdparse.ChoiceContext[]?
---    A description of how / when this function is called. It gets passed to
---    `cmdparse.Parameter.choices()`.
---@param options mega.cmdparse._core.DisplayOptions?
---    Control minor behaviors of this function. e.g. What data to show.
---@return string[]
---    The matched parameters, if any.
---
function M.get_matching_partial_flag_text(prefix, flags, value, contexts, options)
    ---@type string[]
    local output = {}

    ---@type string[]
    local excluded_names = {}

    if options then
        excluded_names = options.excluded_names or {}
    end

    for _, parameter in ipairs(iterator_helper.sort_parameters(flags)) do
        if not parameter:is_exhausted() then
            for _, name in ipairs(parameter.names) do
                if vim.tbl_contains(excluded_names, name) then
                    _LOGGER:fmt_debug('Skipped adding "%s" because it was found in "%s".', parameter, excluded_names)

                    break
                elseif name == prefix then
                    if parameter:get_nargs() == 1 then
                        if not value then
                            table.insert(output, parameter.names[1] .. "=")
                        else
                            vim.list_extend(output, _get_single_choices_text(parameter, value, contexts))
                        end
                    else
                        table.insert(output, name)
                    end

                    break
                elseif vim.startswith(name, prefix) then
                    if parameter:get_nargs() == 1 then
                        table.insert(output, name .. "=")
                    else
                        table.insert(output, name)
                    end

                    break
                end
            end
        end
    end

    return output
end

--- Find all `options` that match `name`.
---
--- By default a position option takes any argument / value. Some position parameters
--- have specific, required choice(s) that this function means to match.
---
---@param name string
---    The user's input text to try to match.
---@param parameters mega.cmdparse.Parameter[]
---    All position parameters to check.
---@param contexts mega.cmdparse.ChoiceContext[]?
---    A description of how / when this function is called. It gets passed to
---    `mega.cmdparse.Parameter.choices()`.
---@return mega.cmdparse.Parameter[] # The found matches, if any.
---
function M.get_matching_position_parameters(name, parameters, contexts)
    contexts = contexts or {}
    ---@type string[]
    local choices = {}

    for _, parameter in ipairs(iterator_helper.sort_parameters(parameters)) do
        if not parameter:is_exhausted() and parameter.choices then
            vim.list_extend(
                choices,
                texter.get_array_startswith(
                    parameter.choices({
                        contexts = vim.list_extend({ constant.ChoiceContext.position_matching }, contexts),
                        current_value = name,
                    }),
                    name
                )
            )
        end
    end

    ---@type string[]
    local output = {}

    for _, text in ipairs(choices) do
        table.insert(output, text_parse.escape_argument(text))
    end

    return output
end

--- Find all all child parsers that start with `prefix`, starting from `parser`.
---
--- This function is **exclusive** - `parser` cannot be returned from this function.
---
---@param prefix string Some text to search for.
---@param parser mega.cmdparse.ParameterParser The starting point to search within.
---@return string[] # The names of all matching child parsers.
---
function M.get_matching_subparser_names(prefix, parser)
    ---@type string[]
    local output = {}

    for parser_ in iterator_helper.iter_parsers(parser) do
        local names = parser_:get_names()

        vim.list_extend(output, texter.get_array_startswith(names, prefix))
    end

    return output
end

--- Get the next auto-complete options for `parser`.
---
---@param parser mega.cmdparse.ParameterParser
---    The starting point to search within.
---@param prefix string
---    The name of the flag that must match, exactly or partially.
---@param value string
---    If the user provided a (exact or partial) value for the flag / named
---    position, the text is given here.
---@param contexts mega.cmdparse.ChoiceContext[]
---    A description of how / when this function is called. It gets passed to
---    `mega.cmdparse.Parameter.choices()`.
---@param options mega.cmdparse._core.DisplayOptions?
---    Control minor behaviors of this function. e.g. What data to show.
---@return string[]
---    All auto-completion results found, if any.
---
function M.get_parser_exact_or_partial_matches(parser, prefix, value, contexts, options)
    prefix = _remove_contiguous_whitespace(prefix)
    ---@type string[]
    local output = {}

    vim.list_extend(output, M.get_matching_position_parameters(prefix, parser:get_position_parameters(), contexts))
    vim.list_extend(
        output,
        M.get_matching_partial_flag_text(prefix, parser:get_flag_parameters(), value, contexts, options)
    )

    return output
end

return M
