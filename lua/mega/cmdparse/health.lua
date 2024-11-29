--- Make sure `cmdparse` will work as expected.
---
--- At minimum, we validate that the user's configuration is correct. But other
--- checks can happen here if needed.
---
---@module 'mega.cmdparse.health'
---

local configuration_ = require("mega.cmdparse._core.configuration")
local tabler = require("mega.cmdparse._core.tabler")
local logging_ = require("mega.logging")

local _LOGGER = logging_.get_logger("mega.cmdparse.health")
local M = {}

-- NOTE: This file is defer-loaded so it's okay to run this in the global scope
configuration_.initialize_data_if_needed()

--- Add issues to `array` if there are errors.
---
--- Todo:
---     Once Neovim 0.10 is dropped, use the new function signature
---     for vim.validate to make this function cleaner.
---
---@param array string[]
---    All of the cumulated errors, if any.
---@param name string
---    The key to check for.
---@param value_creator fun(): any
---    A function that generates the value.
---@param expected string | fun(value: any): boolean
---    If `value_creator()` does not match `expected`, this error message is
---    shown to the user.
---@param message (string | boolean)?
---    If it's a string, it's the error message when
---    `value_creator()` does not match `expected`. When it's
---    `true`, it means it's okay for `value_creator()` not to match `expected`.
---
local function _append_validated(array, name, value_creator, expected, message)
    local success, value = pcall(value_creator)

    if not success then
        table.insert(array, value)

        return
    end

    local validated
    success, validated = pcall(vim.validate, {
        -- TODO: I think the Neovim type annotation is wrong. Once Neovim
        -- 0.10 is dropped let's just change this over to the new
        -- vim.validate signature.
        --
        ---@diagnostic disable-next-line: assign-type-mismatch
        [name] = { value, expected, message },
    })

    if not success then
        table.insert(array, validated)
    end
end

--- Check if `data` is a boolean under `key`.
---
---@param key string The configuration value that we are checking.
---@param data any The object to validate.
---@return string? # The found error message, if any.
---
local function _get_boolean_issue(key, data)
    local success, message = pcall(vim.validate, {
        [key] = {
            data,
            function(value)
                if value == nil then
                    -- NOTE: This value is optional so it's fine it if is not defined.
                    return true
                end

                return type(value) == "boolean"
            end,
            -- TODO: I think the Neovim type annotation is wrong. Once Neovim
            -- 0.10 is dropped let's just change this over to the new
            -- vim.validate signature.
            --
            ---@diagnostic disable-next-line: assign-type-mismatch
            "a boolean",
        },
    })

    if success then
        return nil
    end

    return message
end

--- Check all "cmdparse" values for issues.
---
---@param data mega.cmdparse.Configuration All of the user's fallback settings.
---@return string[] # All found issues, if any.
---
local function _get_cmdparse_issues(data)
    local output = {}

    _append_validated(output, "cmdparse.auto_complete.display.help_flag", function()
        return tabler.get_value(data, { "cmdparse", "auto_complete", "display", "help_flag" })
    end, "boolean", true)

    return output
end

--- Check if logging configuration `data` has any issues.
---
---@param data mega.cmdparse.LoggingConfiguration The user's logger settings.
---@return string[] # All of the found issues, if any.
---
local function _get_logging_issues(data)
    local output = {}

    _append_validated(output, "logging", function()
        return data
    end, function(value)
        if type(value) ~= "table" then
            return false
        end

        return true
    end, 'a table. e.g. { level = "info", ... }')

    if not vim.tbl_isempty(output) then
        return output
    end

    _append_validated(output, "logging.level", function()
        return data.level
    end, function(value)
        if type(value) ~= "string" then
            return false
        end

        if not vim.tbl_contains({ "trace", "debug", "info", "warn", "error", "fatal" }, value) then
            return false
        end

        return true
    end, 'an enum. e.g. "trace" | "debug" | "info" | "warn" | "error" | "fatal"')

    local message = _get_boolean_issue("logging.use_console", data.use_console)

    if message ~= nil then
        table.insert(output, message)
    end

    message = _get_boolean_issue("logging.use_file", data.use_file)

    if message ~= nil then
        table.insert(output, message)
    end

    return output
end

--- Check `data` for problems and return each of them.
---
---@param data mega.cmdparse.Configuration? All extra customizations for this plugin.
---@return string[] # All found issues, if any.
---
function M.get_issues(data)
    if not data or vim.tbl_isempty(data) then
        data = configuration_.resolve_data(vim.g.cmdparse_configuration)
    end

    local output = {}
    vim.list_extend(output, _get_cmdparse_issues(data))

    local logging = data.logging

    if logging ~= nil then
        vim.list_extend(output, _get_logging_issues(data.logging))
    end

    return output
end

--- Make sure `data` will work for `cmdparse`.
---
---@param data mega.cmdparse.Configuration? All extra customizations for this plugin.
---
function M.check(data)
    _LOGGER:debug("Running cmdparse health check.")

    vim.health.start("Configuration")

    local issues = M.get_issues(data)

    if vim.tbl_isempty(issues) then
        vim.health.ok("Your vim.g.cmdparse_configuration variable is great!")
    end

    for _, issue in ipairs(issues) do
        vim.health.error(issue)
    end
end

return M
