--- Run the is file before you run unittests to download any extra dependencies.

vim.opt.rtp:append(".")

vim.cmd("runtime plugin/cmdparse.lua")

require("mega.cmdparse._core.configuration").initialize_data_if_needed()
