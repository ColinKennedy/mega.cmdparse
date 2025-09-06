--- Simple auto-completion customization functions.

local _PATH_SEPARATOR = package.config:sub(1, 1) -- NOTE: "\" on Windows, "/" on Unix

---@class mega.cmdparse.completion.arguments.options
---@field filter (fun(path: string): boolean)? Return `true` to exclude a path.
local M = {}

---@param data mega.cmdparse.ChoiceData? The current context information.
---@return string[] # All files on-disk that match the current `data` value.
local function _path(data)
    if not data then
        return {}
    end

    local wild_ignore = false
    local as_list = true

    local pattern = data.current_value .. "*"

    return vim.fn.glob(pattern, wild_ignore, as_list)
end

--- Make a function that finds all directories on-disk.
---
---@param options mega.cmdparse.completion.arguments.options?
---@return fun(data: mega.cmdparse.ChoiceData?): string[] # The auto-complete function.
---
function M.directory(options)
    local filter

    if options and options.filter then
        filter = options.filter
    end

    ---@param data mega.cmdparse.ChoiceData? The current context information.
    ---@return string[] # All directories on-disk that match the current `data` value.
    local function wrapped(data)
        if not data then
            return {}
        end

        local wild_ignore = false
        local as_list = true

        local pattern = data.current_value .. "*" .. _PATH_SEPARATOR

        ---@type string[]
        local output = {}

        for _, path in ipairs(vim.fn.glob(pattern, wild_ignore, as_list)) do
            if not filter or not filter(path) then
                table.insert(output, path)
            end
        end

        return output
    end

    return wrapped
end

--- Make a function that finds all files on-disk.
---
---@param options mega.cmdparse.completion.arguments.options?
---@return fun(data: mega.cmdparse.ChoiceData?): string[] # The auto-complete function.
---
function M.file(options)
    local filter

    if options and options.filter then
        filter = options.filter
    end

    ---@param data mega.cmdparse.ChoiceData? The current context information.
    ---@return string[] # All files on-disk that match the current `data` value.
    local wrapped = function(data)
        ---@type string[]
        local output = {}

        for _, path in ipairs(_path(data)) do
            if vim.fn.filereadable(path) == 1 and (not filter or not filter(path)) then
                table.insert(output, path)
            end
        end

        return output
    end

    return wrapped
end

--- Make a function that finds all files and directories on-disk.
---
---@param options mega.cmdparse.completion.arguments.options?
---@return fun(data: mega.cmdparse.ChoiceData?): string[] # The auto-complete function.
---
function M.path(options)
    local filter

    if options and options.filter then
        filter = options.filter
    end

    ---@param data mega.cmdparse.ChoiceData? The current context information.
    ---@return string[] # All files on-disk that match the current `data` value.
    local wrapped = function(data)
        ---@type string[]
        local output = {}

        for _, path in ipairs(_path(data)) do
            if not filter or not filter(path) then
                table.insert(output, path)
            end
        end

        return output
    end

    return wrapped
end

return M
