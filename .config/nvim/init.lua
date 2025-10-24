-- Leader must be set before lazy loading plugins
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Load plugins after runtimepath is set
vim.cmd('packloadall')

-- Leap configuration - swap default mappings
vim.keymap.set({'n', 'x', 'o'}, 's', '<Plug>(leap-anywhere)')  -- All windows (including current)
vim.keymap.set('n', 'S', '<Plug>(leap)')  -- Current window only

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

-- fzf-lua Configuration
require("fzf-lua").setup({
  keymap = {
    builtin = {
      ["<C-d>"] = "preview-page-down",
      ["<C-u>"] = "preview-page-up",
    },
  },

  -- No 'files', 'grep', or 'live_grep' overrides are needed.
  -- fzf-lua will automatically use 'fd' and 'rg' if they are
  -- available on your $PATH, and they will respect your
  -- .gitignore and .rgignore files.
})

require("auto-save").setup({
  verbose = true,
})
require("quickbuild").setup()
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"  -- Recommended by auto-session
require("auto-session").setup({
  auto_save = true,
  auto_restore = true,
  auto_create = true,
})

-- Clang-format configuration
vim.g['clang_format#code_style'] = 'chromium'
vim.g['clang_format#auto_format'] = 0

-- Some basic quality of life items
vim.opt.number = true 		-- Show line numbers
vim.opt.ignorecase = true	-- Ignore case ...
vim.opt.smartcase = true	-- ... unless specified
vim.opt.termguicolors = true	-- 24bit color
vim.opt.mouse = 'a'		-- Mouse in all modes
vim.opt.fillchars:append({ eob = " ", vert = " " })  -- Hide tildes and buffer dividers
vim.opt.signcolumn = "yes:1"	-- Always show 1-char sign column

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

-- fzf-lua keybinds
vim.keymap.set("n", "<leader>f", "<cmd>FzfLua files<cr>")
vim.keymap.set("n", "<leader>g", "<cmd>FzfLua live_grep<cr>")
vim.keymap.set("n", "<leader>b", "<cmd>FzfLua buffers<cr>")
vim.keymap.set("n", "<leader>h", "<cmd>FzfLua help_tags<cr>")
vim.keymap.set("n", "<leader>e", "<cmd>FzfLua diagnostics_workspace<cr>")
vim.keymap.set("n", "<leader>s", "<cmd>AutoSession search<cr>")

-- Format and save
vim.keymap.set("n", "<leader>w",  "<cmd>ClangFormat<cr><cmd>write<cr>")

-- QuickBuild keybinds
vim.keymap.set("n", "<leader>bb", "<cmd>QuickBuild<cr>")
vim.keymap.set("n", "<leader>bc", "<cmd>QuickBuildCancel<cr>")

-- Diagnostic navigation
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float)


--
-- SCROLLING
--

vim.opt.scroll = 10;
vim.opt.scrolloff = 5;

-- Neovide animation speed
vim.g.neovide_scroll_animation_length = 0.3
vim.g.neovide_cursor_animation_length = 0.1

--- Gets the amount to scroll, respecting 'scroll' (0 = half-window)
local function get_scroll_amount()
  local s = vim.opt.scroll:get()
  return s > 0 and s or math.floor(vim.api.nvim_win_get_height(0) / 2)
end

--- Scrolls the window down, bringing the cursor if 'scrolloff' is set.
local function scroll_down()
  local amount = get_scroll_amount()
  local win = 0
  local buf = 0
  
  -- Get current view
  local current_top = vim.fn.line('w0')
  local height = vim.api.nvim_win_get_height(win)
  local total_lines = vim.api.nvim_buf_line_count(buf)
  
  -- Calculate new top line
  local max_top = math.max(1, total_lines - height + 1)
  local new_top = math.min(current_top + amount, max_top)
  
  if new_top == current_top then return end -- No change
  
  -- 1. Perform the scroll (fast, atomic)
  -- This is the correct way to set the topline via the API
  vim.api.nvim_win_call(win, function()
    vim.fn.winrestview({ topline = new_top })
  end)
  
  -- 2. Manually enforce 'scrolloff'
  local so = vim.opt.scrolloff:get()
  local cursor = vim.api.nvim_win_get_cursor(win)
  local cursor_line = cursor[1]
  
  -- Check if cursor is now in the top 'scrolloff' margin
  local safe_line = new_top + so
  if cursor_line < safe_line then
    local new_cursor_line = math.min(safe_line, total_lines)
    vim.api.nvim_win_set_cursor(win, {new_cursor_line, cursor[2]})
  end
end

--- Scrolls the window up, bringing the cursor if 'scrolloff' is set.
local function scroll_up()
  local amount = get_scroll_amount()
  local win = 0
  
  -- Get current view
  local current_top = vim.fn.line('w0')
  
  -- Calculate new top line
  local new_top = math.max(1, current_top - amount)
  
  if new_top == current_top then return end -- No change
  
  -- 1. Perform the scroll (fast, atomic)
  vim.api.nvim_win_call(win, function()
    vim.fn.winrestview({ topline = new_top })
  end)
  
  -- 2. Manually enforce 'scrolloff'
  local so = vim.opt.scrolloff:get()
  local height = vim.api.nvim_win_get_height(win)
  local cursor = vim.api.nvim_win_get_cursor(win)
  local cursor_line = cursor[1]
  
  -- Check if cursor is now in the bottom 'scrolloff' margin
  local safe_line = new_top + height - 1 - so
  if cursor_line > safe_line then
    local new_cursor_line = math.max(1, safe_line)
    vim.api.nvim_win_set_cursor(win, {new_cursor_line, cursor[2]})
  end
end

---
-- MAPPINGS
---
local map_opts = { noremap = true, silent = true }

-- For n, i, v, the Lua function can be called directly.
vim.keymap.set({'n', 'i', 'v'}, '<C-d>', scroll_down, map_opts)
vim.keymap.set({'n', 'i', 'v'}, '<C-u>', scroll_up, map_opts)

-- For 't' (terminal) mode, we MUST use <Cmd> to prevent
-- sending the keys to the running shell.
vim.keymap.set('t', '<C-d>', '<Cmd>lua scroll_down()<CR>', map_opts)
vim.keymap.set('t', '<C-u>', '<Cmd>lua scroll_up()<CR>', map_opts)---

-- Don't auto-equalize splits on open/close
vim.opt.equalalways = false

-- Split navigation and management (work in all modes)
vim.keymap.set({'n', 'i', 'v', 't'}, '<M-]>', '<Esc><C-w>w', { noremap = true, silent = true })  -- Cycle forward (Alt+])
vim.keymap.set({'n', 'i', 'v', 't'}, '<M-[>', '<Esc><C-w>W', { noremap = true, silent = true })  -- Cycle backward (Alt+[)
vim.keymap.set({'n', 'i', 'v', 't'}, '<M-{>', '<Esc><C-w>c', { noremap = true, silent = true })  -- Close split (Alt+{)
vim.keymap.set({'n', 'i', 'v', 't'}, '<M-}>', '<Esc><C-w>=', { noremap = true, silent = true })  -- Equalize splits (Alt+})
vim.keymap.set({'n', 'i', 'v', 't'}, '<M-C-PageUp>', '<Esc><cmd>vsplit<cr>', { noremap = true, silent = true })  -- Vertical split
vim.keymap.set({'n', 'i', 'v', 't'}, '<M-C-PageDown>', '<Esc><cmd>split<cr>', { noremap = true, silent = true })  -- Horizontal split
vim.keymap.set({'n', 'i', 'v', 't'}, '<M-(>', '<Esc><C-w>5<', { noremap = true, silent = true })  -- Decrease width (Alt+()
vim.keymap.set({'n', 'i', 'v', 't'}, '<M-)>', '<Esc><C-w>5>', { noremap = true, silent = true })  -- Increase width (Alt+))

-- OS-specific font configuration for Neovide
if vim.fn.has("win32") == 1 then
  -- Windows
  vim.o.guifont = "Consolas:h14"
elseif vim.fn.has("macunix") == 1 then
  -- macOS
  vim.o.guifont = "Menlo:h14"
else
  -- Linux
  vim.o.guifont = "DejaVu Sans Mono:h14"
end


