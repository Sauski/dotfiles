require('leap').set_default_mappings()

-- Leader
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Some basic quality of life items
vim.opt.number = true 		-- Show line numbers
vim.opt.ignorecase = true	-- Ignore case ...
vim.opt.smartcase = true	-- ... unless specified
vim.opt.termguicolors = true	-- 24bit color
vim.opt.mouse = 'a'		-- Mouse in all modes 

-- Spaces over Tabs
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.autoindent = true
vim.opt.expandtab = true
