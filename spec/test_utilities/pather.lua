--- Make file operations easier, for unittests.

---@type string[]
local _DIRECTORIES_TO_DELETE = {}

local M = {}

--- Delete all temporary directories or files that were created during tests.
function M.delete_all_temporary_paths()
    for _, path in ipairs(_DIRECTORIES_TO_DELETE) do
        vim.fn.delete(path)
    end
end

---@return string # Create a directory that should be deleted later.
function M.make_temporary_directory()
    local directory = vim.fn.tempname()
    table.insert(_DIRECTORIES_TO_DELETE, directory)
    vim.fn.mkdir(directory, "p")

    return directory
end

return M
