--- Simple auto-completion customization functions.

local _PATH_SEPARATOR = package.config:sub(1, 1) -- NOTE: "\" on Windows, "/" on Unix

local M = {}

--- Find all directories on-disk that start with the text written in `data`.
---
---@param data mega.cmdparse.ChoiceData? The current context information.
---@return string[] # All directories on-diksk that match the current `data` value.
---
function M.directory(data)
    if not data then
        return {}
    end

    local wild_ignore = false
    local as_list = true

    local pattern = data.current_value .. "*" .. _PATH_SEPARATOR

    return vim.fn.glob(pattern, wild_ignore, as_list)
end

--- Find all files on-disk that start with the text written in `data`.
---
---@param data mega.cmdparse.ChoiceData? The current context information.
---@return string[] # All directories on-diksk that match the current `data` value.
---
function M.file(data)
    ---@type string[]
    local output = {}

    for _, path in ipairs(M.path(data)) do
        if vim.fn.filereadable(path) == 1 then
            table.insert(output, path)
        end
    end

    return output
end

--- Find all files and directories on-disk that start with the text written in `data`.
---
---@param data mega.cmdparse.ChoiceData? The current context information.
---@return string[] # All directories on-diksk that match the current `data` value.
---
function M.path(data)
    if not data then
        return {}
    end

    local wild_ignore = false
    local as_list = true

    local pattern = data.current_value .. "*"

    return vim.fn.glob(pattern, wild_ignore, as_list)
end

return M
