-- cache.lua: Word extraction and caching per buffer

local M = {}

-- Regex pattern for extracting words (4+ alphanumeric/underscore)
local word_regex = vim.regex([[\<\w\{4,}\>]])

-- Get a hash of buffer content for change detection
local function buffer_hash(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local hash = vim.fn.sha256(table.concat(lines, '\n'))
  return tostring(hash)
end

-- Extract words from buffer content
local function extract_words(bufnr, config)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local text = table.concat(lines, '\n')

  -- Check buffer size limit
  if #text > config.sources.max_buffer_size then
    return {}
  end

  local words = {}
  local word_set = {}
  local pos = 0

  while pos < #text do
    local match_start, match_end = word_regex:match_str(text:sub(pos + 1))
    if not match_start then
      break
    end

    local word = text:sub(pos + match_start + 1, pos + match_end)

    -- Add to set (deduplication)
    if not word_set[word] then
      word_set[word] = true
      table.insert(words, word)

      -- Respect max words limit
      if #words >= config.sources.max_words_per_buffer then
        break
      end
    end

    pos = pos + match_end
  end

  return words
end

-- Get words from a single buffer (with caching)
function M.get_words(bufnr, config)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return {}
  end

  -- Check if buffer should be excluded
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  for _, pattern in ipairs(config.sources.exclude_patterns or {}) do
    if bufname:match(pattern) then
      return {}
    end
  end

  -- Get or create cache table
  local cache = vim.b[bufnr]._sc_cache
  local current_hash = buffer_hash(bufnr)

  -- Return cached words if still valid
  if cache and cache.hash == current_hash then
    return cache.words
  end

  -- Extract words and cache
  local words = extract_words(bufnr, config)
  vim.b[bufnr]._sc_cache = {
    words = words,
    hash = current_hash,
  }

  return words
end

-- Invalidate cache for a buffer
function M.invalidate(bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.b[bufnr]._sc_cache = nil
  end
end

-- Get all words from multiple buffers
function M.get_all_words(bufnrs, config)
  local all_words = {}
  local word_set = {}

  for _, bufnr in ipairs(bufnrs) do
    local words = M.get_words(bufnr, config)
    for _, word in ipairs(words) do
      if not word_set[word] then
        word_set[word] = true
        table.insert(all_words, word)
      end
    end
  end

  return all_words
end

-- Get buffer list based on configuration
function M.get_buffer_list(config)
  local sources = config.sources

  if type(sources.buffers) == 'function' then
    return sources.buffers()
  elseif sources.buffers == 'all' then
    return vim.api.nvim_list_bufs()
  elseif sources.buffers == 'visible' then
    -- Get buffers in visible windows
    local bufnrs = {}
    local seen = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local bufnr = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_is_loaded(bufnr) and not seen[bufnr] then
        table.insert(bufnrs, bufnr)
        seen[bufnr] = true
      end
    end
    return bufnrs
  else
    return {vim.api.nvim_get_current_buf()}
  end
end

return M
