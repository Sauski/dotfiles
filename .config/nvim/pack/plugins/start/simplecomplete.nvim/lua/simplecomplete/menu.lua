-- menu.lua: Custom floating window completion menu

local cache = require('simplecomplete.cache')
local matcher = require('simplecomplete.matcher')

local M = {}

local config = nil
local state = {
  winnr = nil,
  bufnr = nil,
  selected = 1,
  matches = {},
  keyword = '',
  start_col = nil,
  namespace = vim.api.nvim_create_namespace('simplecomplete_menu'),
  augroup = nil,
  keymaps = {},  -- Store keymap info for cleanup
}

-- Setup function
function M.setup(user_config)
  config = user_config
  state.augroup = vim.api.nvim_create_augroup('SimpleCompleteMenu', {clear = true})
end

-- Close the menu
local function close_menu()
  if state.winnr and vim.api.nvim_win_is_valid(state.winnr) then
    vim.api.nvim_win_close(state.winnr, true)
  end
  if state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr) then
    vim.api.nvim_buf_delete(state.bufnr, {force = true})
  end

  -- Remove all keymaps we added
  for _, keymap_info in ipairs(state.keymaps) do
    pcall(vim.keymap.del, keymap_info.mode, keymap_info.lhs, {buffer = keymap_info.buffer})
  end

  state.winnr = nil
  state.bufnr = nil
  state.matches = {}
  state.selected = 1
  state.keymaps = {}

  -- Clear autocmds
  vim.api.nvim_clear_autocmds({group = state.augroup})
end

-- Update menu display
local function update_display()
  if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
    return
  end

  local lines = {}
  for _, match in ipairs(state.matches) do
    table.insert(lines, match)
  end

  vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, lines)

  -- Highlight selected line
  vim.api.nvim_buf_clear_namespace(state.bufnr, state.namespace, 0, -1)
  if state.selected > 0 and state.selected <= #state.matches then
    vim.api.nvim_buf_add_highlight(
      state.bufnr,
      state.namespace,
      'PmenuSel',
      state.selected - 1,
      0,
      -1
    )
  end
end

-- Accept selected completion
local function accept_completion()
  if #state.matches == 0 or state.selected < 1 or state.selected > #state.matches then
    close_menu()
    return
  end

  local selected_match = state.matches[state.selected]

  -- Get current cursor position
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1  -- 0-indexed for nvim_buf_set_text
  local col = cursor[2]      -- Already 0-indexed

  -- Calculate keyword start position
  local keyword_start_col = col - #state.keyword

  close_menu()

  -- Replace the keyword with the selected match
  vim.api.nvim_buf_set_text(
    0,                    -- current buffer
    row,                  -- start row
    keyword_start_col,    -- start col
    row,                  -- end row
    col,                  -- end col
    {selected_match}      -- replacement text
  )

  -- Move cursor to end of inserted text
  vim.api.nvim_win_set_cursor(0, {row + 1, keyword_start_col + #selected_match})
end

-- Move selection up
local function select_prev()
  if #state.matches == 0 then return end
  state.selected = state.selected - 1
  if state.selected < 1 then
    state.selected = #state.matches
  end
  update_display()
end

-- Move selection down
local function select_next()
  if #state.matches == 0 then return end
  state.selected = state.selected + 1
  if state.selected > #state.matches then
    state.selected = 1
  end
  update_display()
end

-- Refresh matches based on current keyword
local function refresh_matches()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  local col = cursor[2]

  local keyword = matcher.get_keyword(line, col)

  if #keyword == 0 then
    close_menu()
    return
  end

  -- Get new matches
  local bufnrs = cache.get_buffer_list(config)
  local words = cache.get_all_words(bufnrs, config)
  local new_matches = matcher.find_matches(keyword, words, config)

  if #new_matches == 0 then
    close_menu()
    return
  end

  state.matches = new_matches
  state.keyword = keyword
  state.selected = math.min(state.selected, #new_matches)

  update_display()
end

-- Show completion menu
function M.show()
  if vim.api.nvim_get_mode().mode ~= 'i' then
    return
  end

  -- Get initial matches
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  local col = cursor[2]

  local keyword = matcher.get_keyword(line, col)

  if #keyword == 0 then
    return
  end

  local bufnrs = cache.get_buffer_list(config)
  local words = cache.get_all_words(bufnrs, config)
  local matches = matcher.find_matches(keyword, words, config)

  if #matches == 0 then
    return
  end

  -- Store state
  state.matches = matches
  state.keyword = keyword
  state.selected = 1

  -- Create buffer
  state.bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(state.bufnr, 'bufhidden', 'wipe')

  -- Calculate dimensions
  local win_height = math.min(#matches, 10)
  local win_width = 0
  for _, match in ipairs(matches) do
    win_width = math.max(win_width, #match + 3)
  end
  win_width = math.min(win_width, 50)

  -- Create floating window positioned below cursor
  state.winnr = vim.api.nvim_open_win(state.bufnr, false, {
    relative = 'cursor',
    row = 1,       -- 1 row below cursor
    col = 0,       -- At cursor column
    width = win_width,
    height = win_height,
    style = 'minimal',
    border = 'single',
    zindex = 50,
  })

  vim.api.nvim_win_set_option(state.winnr, 'winhl', 'Normal:Pmenu,FloatBorder:PmenuBorder')

  update_display()

  -- Set up keymaps and track them for cleanup
  local opts = {buffer = true, noremap = true, silent = true}
  local keymaps_to_add = {
    {'i', '<Down>', select_next},
    {'i', '<C-n>', select_next},
    {'i', '<Up>', select_prev},
    {'i', '<C-p>', select_prev},
    {'i', '<CR>', accept_completion},
    {'i', '<Esc>', close_menu},
    {'i', '<C-c>', close_menu},
  }

  for _, km in ipairs(keymaps_to_add) do
    vim.keymap.set(km[1], km[2], km[3], opts)
    table.insert(state.keymaps, {mode = km[1], lhs = km[2], buffer = true})
  end

  -- Auto-refresh on text change
  vim.api.nvim_create_autocmd('TextChangedI', {
    group = state.augroup,
    callback = refresh_matches,
  })

  -- Close on cursor move to different line or leaving insert
  vim.api.nvim_create_autocmd({'InsertLeave', 'CursorMovedI'}, {
    group = state.augroup,
    callback = function(ev)
      if ev.event == 'InsertLeave' then
        close_menu()
        return
      end

      -- Check if cursor moved to different line
      local new_cursor = vim.api.nvim_win_get_cursor(0)
      if new_cursor[1] ~= cursor[1] then
        close_menu()
      end
    end,
  })
end

return M
