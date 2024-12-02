--- Temporarily track when certain built-in Vim commands are called.
---
---@module 'test_utilities.mock_vim'
---

local M = {}

local _HEALTH_ERROR_MESSAGES = {}
local _NOTIFICATIONS = {}
local _PRINTS = {}

local _ORIGINAL_HEALTH_ERROR = vim.health.error
local _ORIGINAL_NOTIFY = vim.notify
local _ORIGINAL_PRINT = print

local _MOCKED_PRINT = function(message)
    table.insert(_PRINTS, message)
end

local _MOCKED_NOTIFY = function(...)
    local data = { ... }
    local level = data[2]
    table.insert(_NOTIFICATIONS, data[1])

    if level == vim.log.levels.ERROR then
        -- NOTE: This level triggers errors in Vim's UI so we can't not send
        -- these notifications. Otherwise unittests that are meant to error
        -- will pass by accident instead.
        --
        _ORIGINAL_NOTIFY(...)
    end
end

---@return string[] # Get all saved `print` calls.
function M.get_prints()
    return _PRINTS
end

---@return string[] # Get all saved vim.health.error calls.
function M.get_vim_health_errors()
    return _HEALTH_ERROR_MESSAGES
end

---@return string[] # All of found, tracked vim.notify calls.
function M.get_vim_notify_messages()
    return _NOTIFICATIONS
end

--- Redirect `print` calls to a different function.
function M.mock_print()
    print = _MOCKED_PRINT -- luacheck: ignore 121
end

--- Temporarily track vim.health calls.
function M.mock_vim_health()
    local function _save_health_error_message(message)
        table.insert(_HEALTH_ERROR_MESSAGES, message)
    end

    vim.health.error = _save_health_error_message
end

--- Track vim.notify messages, for unittests.
function M.mock_vim_notify()
    vim.notify = _MOCKED_NOTIFY
end

--- Reset all mocked vim.notify messages.
function M.reset_vim_notify()
    vim.notify = _ORIGINAL_NOTIFY
    _NOTIFICATIONS = {}
end

--- Reset all mocked print messages.
function M.reset_print()
    print = _ORIGINAL_PRINT -- luacheck: ignore 121
    _PRINTS = {}
end

--- Restore the previous vim.health function.
function M.reset_mocked_vim_health()
    vim.health.error = _ORIGINAL_HEALTH_ERROR
    _HEALTH_ERROR_MESSAGES = {}
end

return M
