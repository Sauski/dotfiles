-- trigger.lua: Event handling and LCP completion triggering

local cache = require('simplecomplete.cache')
local matcher = require('simplecomplete.matcher')
local indicator = require('simplecomplete.indicator')

local M = {}

local timer = nil
local config = nil

-- Completion state
local state = {
  completion_text = nil,
  lcp = nil,           -- Full LCP (for case correction)
  keyword = nil,       -- Original keyword typed
  bufnr = nil,
  line_nr = nil,
  col = nil,
}

-- Track initial insert state for newly-typed character counting
local insert_state = {}

-- Trigger completion check
local function do_completion()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line_nr = cursor[1]
  local col = cursor[2]
  local line = vim.api.nvim_get_current_line()

  local keyword = matcher.get_keyword(line, col)

  local check_length = #keyword
  if insert_state.bufnr == bufnr and insert_state.line_nr == line_nr then
    local initial_keyword = insert_state.keyword or ''
    local keyword_lower = keyword:lower()
    local initial_lower = initial_keyword:lower()

    if #keyword > #initial_keyword and keyword_lower:sub(1, #initial_lower) == initial_lower then
      check_length = #keyword - #initial_keyword
    end
  end

  if check_length < config.min_keyword_length then
    indicator.hide(bufnr)
    state.completion_text = nil
    return
  end

  if matcher.is_mid_word(line, col) then
    indicator.hide(bufnr)
    state.completion_text = nil
    return
  end

  local bufnrs = cache.get_buffer_list(config)
  local words = cache.get_all_words(bufnrs, config)
  local matches = matcher.find_matches(keyword, words, config)

  -- Get LCP for counting changes
  local lcp = nil
  if #matches > 0 then
    lcp = matcher.longest_common_prefix(matches)
  end

  -- Count total changes (new chars + case diffs)
  local total_changes = 0
  if lcp then
    total_changes = matcher.count_completion_changes(keyword, lcp)
  end

  -- Show indicator: initial trigger needs min_completion_changes, but persist while changes >= 0
  local had_completion = state.completion_text ~= nil
  local should_show = (total_changes >= config.min_completion_changes) or (had_completion and total_changes >= 0)

  if lcp and should_show then
    local completion = matcher.get_unambiguous_completion(keyword, matches)
    if completion then
      indicator.show(bufnr, line_nr, col)
      state.completion_text = completion
      state.lcp = lcp
      state.keyword = keyword
      state.bufnr = bufnr
      state.line_nr = line_nr
      state.col = col
      return
    end
  end

  indicator.hide(bufnr)
  state.completion_text = nil
  state.lcp = nil
  state.keyword = nil
end

-- Schedule completion with debouncing
local function schedule_completion()
  if timer then
    timer:stop()
  end

  timer = vim.loop.new_timer()
  timer:start(config.debounce_ms, 0, vim.schedule_wrap(function()
    do_completion()
  end))
end

-- Handle text changed event
local function on_text_changed()
  schedule_completion()
end

-- Handle entering insert mode
local function on_insert_enter()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line_nr = cursor[1]
  local col = cursor[2]
  local line = vim.api.nvim_get_current_line()

  insert_state = {
    bufnr = bufnr,
    line_nr = line_nr,
    col = col,
    keyword = matcher.get_keyword(line, col),
  }
end

-- Handle leaving insert mode
local function on_insert_leave()
  local bufnr = vim.api.nvim_get_current_buf()
  indicator.hide(bufnr)

  if timer then
    timer:stop()
    timer = nil
  end

  insert_state = {}
  state.completion_text = nil
  state.lcp = nil
  state.keyword = nil

  cache.invalidate(bufnr)
end

-- Accept LCP completion (for expr mapping - returns text to insert)
function M.accept_completion()
  if not state.completion_text or not state.lcp or not state.keyword then
    return nil
  end

  local lcp = state.lcp
  local keyword = state.keyword
  local bufnr = state.bufnr

  -- Clear state
  state.completion_text = nil
  state.lcp = nil
  state.keyword = nil
  indicator.hide(bufnr)

  -- Schedule recomputation after insertion
  vim.schedule(function()
    schedule_completion()
  end)

  -- Return key sequence: backspaces to delete keyword, then LCP with correct case
  -- Use \b (backspace character) which works in key sequences
  local backspaces = string.rep("\b", #keyword)
  return backspaces .. lcp
end

-- Get matches for menu
function M.get_matches_for_menu()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local col = cursor[2]
  local line = vim.api.nvim_get_current_line()

  local keyword = matcher.get_keyword(line, col)

  if #keyword == 0 then
    return nil, nil
  end

  local bufnrs = cache.get_buffer_list(config)
  local words = cache.get_all_words(bufnrs, config)
  local matches = matcher.find_matches(keyword, words, config)

  return matches, keyword
end

-- Setup autocmds
function M.setup(user_config)
  config = user_config

  local augroup = vim.api.nvim_create_augroup('SimpleComplete', {clear = true})

  vim.api.nvim_create_autocmd({'InsertEnter'}, {
    group = augroup,
    callback = on_insert_enter,
  })

  vim.api.nvim_create_autocmd({'TextChangedI'}, {
    group = augroup,
    callback = on_text_changed,
  })

  vim.api.nvim_create_autocmd({'CursorMovedI'}, {
    group = augroup,
    callback = function()
      local cursor = vim.api.nvim_win_get_cursor(0)
      local line_nr = cursor[1]

      if insert_state.line_nr and line_nr ~= insert_state.line_nr then
        insert_state = {}
      end

      schedule_completion()
    end,
  })

  vim.api.nvim_create_autocmd({'InsertLeave'}, {
    group = augroup,
    callback = on_insert_leave,
  })

  vim.api.nvim_create_autocmd({'BufWritePost', 'TextChanged'}, {
    group = augroup,
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      cache.invalidate(bufnr)
    end,
  })
end

return M
