-- Minimal init for tests
local root = vim.fn.getcwd()
vim.opt.runtimepath:append(root)
vim.opt.runtimepath:append(root .. "/lib/plenary.nvim")

vim.cmd("runtime! plugin/**/*.lua")
