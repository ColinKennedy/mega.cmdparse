--- Run the is file before you run unittests to download any extra dependencies.

--- Run the is file before you run unittests to download any extra dependencies.

local _PLUGINS = {
    ["https://github.com/ColinKennedy/mega.logging"] = os.getenv("MEGA_LOGGING_DIR") or "/tmp/mega.logging",
}

local cloned = false

for url, directory in pairs(_PLUGINS) do
    if vim.fn.isdirectory(directory) ~= 1 then
        print(string.format('Cloning "%s" plug-in to "%s" path.', url, directory))

        vim.fn.system({ "git", "clone", url, directory })

        cloned = true
    end

    vim.opt.rtp:append(directory)
end

if cloned then
    print("Finished cloning.")
end
vim.opt.rtp:append(".")

vim.cmd("runtime plugin/cmdparse.lua")

-- NOTE: Quiet logging so it doesn't distract from tests
local logging = require("mega.logging")

logging._DEFAULTS.use_console = false
