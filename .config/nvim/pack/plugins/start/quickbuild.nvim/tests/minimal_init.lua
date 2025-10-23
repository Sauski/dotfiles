-- Minimal init for tests
vim.opt.runtimepath:append(".")
vim.opt.runtimepath:append("./lib/plenary.nvim")

vim.cmd("runtime! plugin/**/*.lua")
