-- matcher.lua: Prefix filtering and keyword extraction

local M = {}

-- Extract the keyword before the cursor
function M.get_keyword(line, col)
  if not line or col < 1 then
    return ''
  end

  local before_cursor = line:sub(1, col)
  local keyword = before_cursor:match('[%w_]+$') or ''
  return keyword
end

-- Check if we're inserting mid-word (word character after cursor)
function M.is_mid_word(line, col)
  if col >= #line then
    return false
  end

  local char_after = line:sub(col + 1, col + 1)
  return char_after:match('[%w_]') ~= nil
end

-- Apply configured filters to a word
local function apply_filters(word, config)
  local filters = config.filters

  -- Filter out paths
  if filters.no_paths and word:match('[/\\]') then
    return false
  end

  -- Filter out file extensions
  if filters.no_extensions and word:match('%.%w+$') then
    return false
  end

  return true
end

-- Find all words matching the prefix (case-insensitive)
function M.find_matches(keyword, words, config)
  if #keyword == 0 then
    return {}
  end

  local keyword_lower = keyword:lower()
  local matches = {}

  for _, word in ipairs(words) do
    -- Skip if same as keyword
    if word ~= keyword then
      local word_lower = word:lower()

      -- Strict prefix match (case-insensitive)
      if word_lower:sub(1, #keyword_lower) == keyword_lower then
        -- Apply filters
        if apply_filters(word, config) then
          table.insert(matches, word)
        end
      end
    end
  end

  return matches
end

-- Get the best match (first match that differs from keyword)
function M.get_best_match(keyword, words, config)
  local matches = M.find_matches(keyword, words, config)

  if #matches == 0 then
    return nil
  end

  -- Return first match
  return matches[1]
end

-- Get the completion text (remainder after keyword)
function M.get_completion_text(keyword, match)
  if not match or #match <= #keyword then
    return ''
  end

  return match:sub(#keyword + 1)
end

-- Count case differences between keyword and the start of word
local function count_case_diffs(keyword, word)
  local diffs = 0

  for i = 1, math.min(#keyword, #word) do
    if keyword:sub(i, i) ~= word:sub(i, i) then
      diffs = diffs + 1
    end
  end

  return diffs
end

-- Calculate longest common prefix across all words (case-insensitive),
-- cased like the word with fewest case differences from keyword
function M.longest_common_prefix(keyword, words)
  if #words == 0 then return "" end

  local cased = words[1]
  local cased_diffs = count_case_diffs(keyword, cased)

  for i = 2, #words do
    local diffs = count_case_diffs(keyword, words[i])
    if diffs < cased_diffs then
      cased = words[i]
      cased_diffs = diffs
    end
  end

  local prefix = cased

  for _, word in ipairs(words) do
    local len = math.min(#prefix, #word)
    local common_len = 0

    for j = 1, len do
      if prefix:sub(j, j):lower() == word:sub(j, j):lower() then
        common_len = j
      else
        break
      end
    end

    prefix = prefix:sub(1, common_len)
    if #prefix == 0 then break end
  end

  return prefix
end

-- Count total changes between typed keyword and LCP
-- Returns: number of new chars + number of case differences
function M.count_completion_changes(typed_keyword, lcp)
  if not lcp or #lcp == 0 then
    return 0
  end

  local new_chars = math.max(0, #lcp - #typed_keyword)

  return count_case_diffs(typed_keyword, lcp) + new_chars
end

-- Get unambiguous completion text based on LCP
function M.get_unambiguous_completion(typed_keyword, matches)
  if #matches == 0 then return nil end

  local lcp = M.longest_common_prefix(typed_keyword, matches)

  if #lcp < #typed_keyword then
    return nil
  end

  if lcp:lower():sub(1, #typed_keyword) ~= typed_keyword:lower() then
    return nil
  end

  return lcp:sub(#typed_keyword + 1)
end

return M
