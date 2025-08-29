--- All function(s) that can be called externally by other Lua modules.
---
--- If a function's signature here changes in some incompatible way, this
--- package must get a new **major** version.
---

local M = {}

M.ParameterParser = {}

--- Create a Neovim command according to `parser`.
---
--- Raises:
---     If `parser` does not have a name defined. It's normally optional for
---     a parser to have a name but here, specifically, it must have a name.
---
---@param parser mega.cmdparse.ParserCreator
---     The top-level command to define.
---@param name string?
---     The name of the Vim command to define. Important: Always start with
---     a capital letter (this is a Vim convention). e.g. `"MyCommand"`.
---@param options vim.api.keyset.user_command?
---     Extra customizations to pass to your command.
---     See `:help nvim_create_user_command()` for details.
---
function M.create_user_command(parser, name, options)
    ---@type mega.cmdparse.ParserCreator
    local caller

    if type(parser) == "function" then
        if not name then
            error(string.format("A parser function was given but no parser name was given."), 0)
        end

        caller = parser
    else
        name = name or parser.name

        if not name then
            error(string.format('Parser "%s" must have a name.', vim.inspect(parser, { depth = 1 })), 0)
        end

        caller = function()
            return parser
        end
    end

    options = vim.tbl_deep_extend("force", {
        nargs = "*",
        complete = M.make_parser_completer(caller),
    }, options or {})

    vim.api.nvim_create_user_command(name, M.make_parser_triager(caller), options)
end

--- Make a function that can auto-complete based on the parser of `parser_creator`.
---
---@param parser_creator mega.cmdparse.ParserCreator
---    A function that creates the decision tree that parses text.
---@return fun(_: any, all_text: string, _: any): string[]?
---    A deferred function that creates the COMMAND mode parser, runs it, and
---    gets all auto-complete values back if any were found.
---
function M.make_parser_completer(parser_creator)
    local cli_subcommand = require("mega.cmdparse._cli.cli_subcommand")

    return cli_subcommand.make_parser_completer(parser_creator)
end

--- Create a deferred function that can parse and execute a user's arguments.
---
---@param parser_creator mega.cmdparse.ParserCreator
---    A function that creates the decision tree that parses text.
---@return fun(options: vim.api.keyset.user_command): nil
---    A function that will parse the user's arguments.
---
function M.make_parser_triager(parser_creator)
    local cli_subcommand = require("mega.cmdparse._cli.cli_subcommand")

    return cli_subcommand.make_parser_triager(parser_creator)
end

--- Create a new `cmdparse.ParameterParser`.
---
--- If the parser is a child of a subparser then this instance must be given
--- a name via `{name="foo"}` or this function will error.
---
---@param options mega.cmdparse.ParameterParserInputOptions | mega.cmdparse.ParameterParserOptions
---    The options that we might pass to `cmdparse.ParameterParser.new`.
---@return mega.cmdparse.ParameterParser
---    The created instance.
---
function M.ParameterParser.new(options)
    local cmdparse = require("mega.cmdparse._cli.cmdparse")
    local configuration = require("mega.cmdparse._core.configuration")

    configuration.initialize_data_if_needed()

    return cmdparse.ParameterParser.new(options)
end

return M
