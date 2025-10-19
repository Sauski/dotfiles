-- Leader must be set before lazy loading plugins
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Load plugins after runtimepath is set
vim.cmd('packloadall')

require('leap').set_default_mappings()

require("nvim-treesitter.install").compilers = { "clang" }

-- Treesitter configuration
require('nvim-treesitter.configs').setup({
  highlight = {
    enable = true,
  },
  indent = {
    enable = true,
  },
})

-- Telescope configuration
-- Patterns to ignore when finding files (ripgrep glob syntax)
local telescope_ignore_globs = {
  "!.git",        -- Exclude .git directory
}

-- Build ripgrep command with ignore patterns
local rg_command = { "rg", "--files", "--hidden" }
for _, pattern in ipairs(telescope_ignore_globs) do
  table.insert(rg_command, "--glob=" .. pattern)
end

require("telescope").setup({
  defaults = {
    mappings = {
      i = { ["<Esc>"] = require("telescope.actions").close },
    },
  },
  pickers = {
    find_files = {
      hidden = true,
      find_command = rg_command,
    },
  },
})
require("auto-save").setup({
  verbose = true,
})
require("quickbuild").setup()

-- Clang-format configuration
vim.g['clang_format#code_style'] = 'chromium'
vim.g['clang_format#auto_format'] = 0

-- Some basic quality of life items
vim.opt.number = true 		-- Show line numbers
vim.opt.ignorecase = true	-- Ignore case ...
vim.opt.smartcase = true	-- ... unless specified
vim.opt.termguicolors = true	-- 24bit color
vim.opt.mouse = 'a'		-- Mouse in all modes

-- Backup and temp files in home directory
local cache_dir = vim.fn.stdpath('cache')
vim.opt.backup = true
vim.opt.backupdir = cache_dir .. '/backup//'
vim.opt.directory = cache_dir .. '/swap//'
vim.opt.undofile = true
vim.opt.undodir = cache_dir .. '/undo//'
vim.fn.mkdir(vim.fn.stdpath('cache') .. '/backup', 'p')
vim.fn.mkdir(vim.fn.stdpath('cache') .. '/swap', 'p')
vim.fn.mkdir(vim.fn.stdpath('cache') .. '/undo', 'p')

-- Gruvbox Material colorscheme
vim.opt.background = 'dark'
vim.g.gruvbox_material_background = 'medium'  -- Options: 'soft', 'medium', 'hard'
vim.g.gruvbox_material_better_performance = 1
vim.cmd('colorscheme gruvbox-material')

-- Override tree-sitter highlighting for built-in types
vim.api.nvim_set_hl(0, "@type.builtin", { fg = "#e78a4e" })  -- Orange (int, string, bool) - distinguishable from yellow 

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
vim.keymap.set("n", "<leader>e",  "<cmd>Telescope diagnostics<cr>")

-- Format and save
vim.keymap.set("n", "<leader>w",  "<cmd>ClangFormat<cr><cmd>write<cr>")

-- QuickBuild keybinds
vim.keymap.set("n", "<leader>bb", "<cmd>QuickBuild<cr>")
vim.keymap.set("n", "<leader>bc", "<cmd>QuickBuildCancel<cr>")

-- Diagnostic navigation
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float)

-- Split navigation (work in all modes)
vim.keymap.set({'n', 'i', 'v', 't'}, '<M-]>', '<Esc><C-w>w', { noremap = true, silent = true })  -- Cycle forward (Alt+])
vim.keymap.set({'n', 'i', 'v', 't'}, '<M-[>', '<Esc><C-w>W', { noremap = true, silent = true })  -- Cycle backward (Alt+[)
vim.keymap.set({'n', 'i', 'v', 't'}, '<M-{>', '<Esc><C-w>c', { noremap = true, silent = true })  -- Close split (Alt+{)
vim.keymap.set({'n', 'i', 'v', 't'}, '<M-}>', '<Esc><C-w>=', { noremap = true, silent = true })  -- Equalize splits (Alt+})
vim.keymap.set({'n', 'i', 'v', 't'}, '<M-C-PageUp>', '<Esc><cmd>vsplit<cr>', { noremap = true, silent = true })  -- Vertical split
vim.keymap.set({'n', 'i', 'v', 't'}, '<M-C-PageDown>', '<Esc><cmd>split<cr>', { noremap = true, silent = true })  -- Horizontal split

