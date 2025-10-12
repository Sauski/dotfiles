-- Leader must be set before lazy loading plugins
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Load plugins after runtimepath is set
vim.cmd('packloadall')

require('leap').set_default_mappings()
require("telescope").setup({
  defaults = {
    mappings = { i = { ["<Esc>"] = require("telescope.actions").close } },
    file_ignore_patterns = {},
    hidden = true,
  },
  pickers = {
    find_files = {
      hidden = true,
    },
  },
})
require("auto-save").setup()

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

-- Telescope keybinds
vim.keymap.set("n", "<leader>f",  "<cmd>Telescope find_files<cr>")
vim.keymap.set("n", "<leader>g",  "<cmd>Telescope live_grep<cr>")
vim.keymap.set("n", "<leader>b",  "<cmd>Telescope buffers<cr>")
vim.keymap.set("n", "<leader>h",  "<cmd>Telescope help_tags<cr>")



