for url, directory in pairs({
    ["https://github.com/echasnovski/mini.doc"] = os.getenv("MINI_DOC_DIRECTORY") or "/tmp/mini.doc",
    ["https://github.com/ColinKennedy/mega.vimdoc"] = os.getenv("AGGRO_VIMDOC_DIRECTORY") or "/tmp/mega.vimdoc",
}) do
    vim.fn.system({ "git", "clone", url, directory })

    vim.opt.rtp:append(directory)
end
