-- Most Recently Used (MRU) buffer tracking

local M = {}

-- Track buffer access times
local mru_order = {}
local mru_counter = 0

-- Update MRU order when a buffer is entered
function M.update()
  local bufnr = vim.api.nvim_get_current_buf()
  mru_counter = mru_counter + 1
  mru_order[bufnr] = mru_counter
end

-- Get MRU timestamp for a buffer (higher = more recent)
function M.get_order(bufnr)
  return mru_order[bufnr] or 0
end

-- Sort function for cokeline: sorts by MRU (most recent first)
function M.sort_buffers(buf1, buf2)
  local order1 = M.get_order(buf1.number)
  local order2 = M.get_order(buf2.number)

  -- If both have been accessed, sort by recency (higher counter = more recent = earlier in list)
  if order1 > 0 and order2 > 0 then
    return order1 > order2
  end

  -- Buffers with access history come before buffers without
  if order1 > 0 then
    return true
  end
  if order2 > 0 then
    return false
  end

  -- Both never accessed: sort by buffer number
  return buf1.number < buf2.number
end

-- Jump to nth buffer in the visible cokeline list
function M.focus_nth_buffer(n)
  local state = require('cokeline.state')

  -- Get visible buffers (already sorted by MRU via our custom sort)
  local visible = state.visible_buffers

  if not visible or #visible < n then
    return
  end

  local target = visible[n]
  if target then
    vim.api.nvim_set_current_buf(target.number)
  end
end

return M
