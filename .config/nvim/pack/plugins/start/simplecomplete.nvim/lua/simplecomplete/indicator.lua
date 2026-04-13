-- indicator.lua: Extmark-based completion indicator

local M = {}

local ns_id = vim.api.nvim_create_namespace('simplecomplete_indicator')

-- Show indicator by highlighting last character before cursor
function M.show(bufnr, line_nr, col)
  M.hide(bufnr)

  if col < 1 then
    return
  end

  local line = vim.api.nvim_buf_get_lines(bufnr, line_nr - 1, line_nr, false)[1]
  if not line or #line == 0 then
    return
  end

  -- Find start of keyword by scanning backwards from cursor
  local start_col = col - 1  -- 0-indexed position before cursor
  while start_col > 0 do
    local char = line:sub(start_col, start_col)
    if not char:match('[%w_]') then
      break
    end
    start_col = start_col - 1
  end

  -- Highlight from keyword start to cursor
  if start_col < 0 or start_col >= col then
    return
  end

  vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_nr - 1, start_col, {
    end_col = col,
    hl_group = 'SimplecompleteIndicator',
    priority = 200,
  })
end

-- Hide indicator
function M.hide(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
end

-- Setup highlight group
function M.setup()
  -- Get Comment color from theme
  local comment_hl = vim.api.nvim_get_hl(0, {name = 'Comment'})
  local comment_color = comment_hl.fg or '#808080'

  vim.api.nvim_set_hl(0, 'SimplecompleteIndicator', {
    underline = true,
    sp = string.format('#%06x', comment_color),
  })
end

return M
