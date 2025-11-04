vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.neovide_input_macos_option_key_is_meta = 'both'

vim.cmd('packloadall')

require('options')
require('appearance')

-- Search improvements
require('auto-hlsearch').setup()

require("nvim-treesitter.install").compilers = { "clang" }
require('nvim-treesitter.configs').setup(require('config.treesitter'))
require('mini.indentscope').setup(require('config.indentscope'))
require("fzf-lua").setup(require('config.fzf'))
require("lualine").setup(require('config.lualine'))
vim.opt.laststatus = 0

require("auto-save").setup({ verbose = true })
require("quickbuild").setup()

require('cokeline').setup(require("config.cokeline"))
require("auto-session").setup({
  auto_save = true,
  auto_restore = true,
  auto_create = true,
})
require("other-nvim").setup(require("config.other").config)

vim.g['clang_format#code_style'] = 'chromium'
vim.g['clang_format#auto_format'] = 0

local buffers = require('config.buffers')
local other = require('config.other')
local editing = require('config.editing')
local scrolling = require('config.scrolling')

vim.keymap.set({'n', 'x', 'o'}, 's', '<Plug>(leap-anywhere)')

vim.keymap.set("n", "<leader>f", "<cmd>FzfLua files<cr>")
vim.keymap.set("n", "<leader>g", "<cmd>FzfLua live_grep<cr>")
vim.keymap.set("n", "<leader>b", "<cmd>FzfLua buffers<cr>")
vim.keymap.set("n", "<leader>h", "<cmd>FzfLua help_tags<cr>")
vim.keymap.set("n", "<leader>e", "<cmd>FzfLua diagnostics_workspace<cr>")
vim.keymap.set("n", "<leader>o", "<cmd>FzfLua oldfiles<cr>")
vim.keymap.set("n", "<leader>l", "<cmd>FzfLua lines<cr>")
vim.keymap.set("n", "<leader>s", "<cmd>AutoSession search<cr>")

vim.keymap.set("n", "<leader>w", "<cmd>ClangFormat<cr><cmd>write<cr>")

vim.keymap.set("n", "<leader>r", other.open_other_in_other_window)
vim.keymap.set("n", "<leader>R", other.open_other_picker)

vim.keymap.set("n", "<leader>bb", "<cmd>QuickBuild<cr>")
vim.keymap.set("n", "<leader>bc", "<cmd>QuickBuildCancel<cr>")

vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float)

vim.keymap.set('n', '<Esc>', function()
  vim.cmd('nohlsearch')
  vim.fn.setreg('/', '')
end, { silent = true })

vim.keymap.set('n', 'S', '<Plug>(cokeline-pick-focus)', { silent = true })
vim.keymap.set('n', '<leader>x', buffers.close_hidden_buffers, { silent = true })
vim.keymap.set({'n', 'i', 'v', 't'}, '<M-{>', buffers.close_current_buffer, { noremap = true, silent = true })

vim.keymap.set('n', 'i', editing.smart_insert('i'), { expr = true, noremap = true })
vim.keymap.set('n', 'a', editing.smart_insert('a'), { expr = true, noremap = true })
vim.keymap.set('n', 'A', editing.smart_insert('A'), { expr = true, noremap = true })

vim.keymap.set({'n', 'i', 'v'}, '<C-d>', scrolling.scroll_down, { noremap = true, silent = true })
vim.keymap.set({'n', 'i', 'v'}, '<C-u>', scrolling.scroll_up, { noremap = true, silent = true })
vim.keymap.set('t', '<C-d>', '<Cmd>lua require("config.scrolling").scroll_down()<CR>', { noremap = true, silent = true })
vim.keymap.set('t', '<C-u>', '<Cmd>lua require("config.scrolling").scroll_up()<CR>', { noremap = true, silent = true })

vim.keymap.set({'n', 'i', 'v', 't'}, '<M-]>', '<Esc><C-w>w', { noremap = true, silent = true })
vim.keymap.set({'n', 'i', 'v', 't'}, '<M-[>', '<Esc><C-w>W', { noremap = true, silent = true })
vim.keymap.set({'n', 'i', 'v', 't'}, '<M-}>', '<Esc><C-w>=', { noremap = true, silent = true })
vim.keymap.set({'n', 'i', 'v', 't'}, '<M-C-PageUp>', '<Esc><cmd>vsplit<cr>', { noremap = true, silent = true })
vim.keymap.set({'n', 'i', 'v', 't'}, '<M-C-PageDown>', '<Esc><cmd>split<cr>', { noremap = true, silent = true })
vim.keymap.set({'n', 'i', 'v', 't'}, '<M-(>', '<Esc><C-w>5<', { noremap = true, silent = true })
vim.keymap.set({'n', 'i', 'v', 't'}, '<M-)>', '<Esc><C-w>5>', { noremap = true, silent = true })
