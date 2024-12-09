--- All functions and data to help customize `cmdparse` for this user.
---
---@module 'mega.cmdparse._core.configuration'
---

local vlog = require("mega.cmdparse._vendors.vlog")

local M = {}

-- NOTE: Don't remove this line. It makes the Lua module much easier to reload
vim.g.loaded_cmdparse = false

---@type mega.cmdparse.Configuration
M.DATA = {
    cmdparse = { auto_complete = { display = { help_flag = true } } },
    logging = { level = "info", use_console = false, use_file = false },
}

--- Setup `cmdparse` for the first time, if needed.
function M.initialize_data_if_needed()
    if vim.g.loaded_cmdparse then
        return
    end

    M.DATA = vim.tbl_deep_extend("force", M.DATA, vim.g.cmdparse_configuration or {})

    vim.g.loaded_cmdparse = true

    vlog.new(M.DATA.logging or {}, true)

    _LOGGER:debug("Initialized cmdparse's configuration.")
end

--- Merge `data` with the user's current configuration.
---
---@param data mega.cmdparse.Configuration? All extra customizations for this plugin.
---@return mega.cmdparse.Configuration # The configuration with 100% filled out values.
---
function M.resolve_data(data)
    M.initialize_data_if_needed()

    return vim.tbl_deep_extend("force", M.DATA, data or {})
end

return M
