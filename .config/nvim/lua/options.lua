vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.inccommand = 'nosplit'
vim.opt.termguicolors = true
vim.opt.mouse = 'a'
vim.opt.fillchars:append({ eob = " ", vert = " " })
vim.opt.signcolumn = "yes:1"
vim.opt_local.numberwidth = 3
vim.opt.showmode = false
vim.opt.laststatus = 0

vim.opt_local.number = true
vim.opt_local.statuscolumn = '%l%=%s'
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter', 'FileType' }, {
  pattern = '*',
  desc = 'Set custom statuscolumn',
  callback = function()
    vim.opt_local.number = true
    vim.opt_local.statuscolumn = '%l%=%s'
  end,
})

local cache_dir = vim.fn.stdpath('cache')
vim.opt.backup = true
vim.opt.backupdir = cache_dir .. '/backup//'
vim.opt.directory = cache_dir .. '/swap//'
vim.opt.undofile = true
vim.opt.undodir = cache_dir .. '/undo//'
vim.fn.mkdir(vim.fn.stdpath('cache') .. '/backup', 'p')
vim.fn.mkdir(vim.fn.stdpath('cache') .. '/swap', 'p')
vim.fn.mkdir(vim.fn.stdpath('cache') .. '/undo', 'p')

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.autoindent = true
vim.opt.expandtab = true

vim.opt.scroll = 10
vim.opt.scrolloff = 5

vim.opt.equalalways = true

vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

if vim.fn.has("win32") == 1 then
  vim.o.guifont = "Consolas:h13"
elseif vim.fn.has("macunix") == 1 then
  vim.o.guifont = "Menlo:h14"
else
  vim.o.guifont = "DejaVu Sans Mono:h14"
end
