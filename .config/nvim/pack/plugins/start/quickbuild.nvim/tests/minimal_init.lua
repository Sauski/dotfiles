-- Minimal init for tests
-- When XDG_* env vars are set, nvim won't load user plugins
local root = vim.fn.getcwd()

-- Convert to absolute path
root = vim.fn.fnamemodify(root, ":p"):gsub("\\", "/"):gsub("/$", "")

-- Add ONLY our local development version to runtimepath
vim.opt.runtimepath:prepend(root .. "/lib/plenary.nvim")
vim.opt.runtimepath:prepend(root)

-- Update Lua package.path to include our lua directories (using ABSOLUTE paths)
package.path = package.path .. ";" .. root .. "/lua/?.lua"
package.path = package.path .. ";" .. root .. "/lua/?/init.lua"
package.path = package.path .. ";" .. root .. "/lib/plenary.nvim/lua/?.lua"
package.path = package.path .. ";" .. root .. "/lib/plenary.nvim/lua/?/init.lua"

-- Load plugins
vim.cmd("runtime! plugin/**/*.lua")
