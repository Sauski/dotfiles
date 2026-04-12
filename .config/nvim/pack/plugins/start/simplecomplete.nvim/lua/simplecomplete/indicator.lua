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

  -- Underline the last character before cursor (col-1 in 0-indexed)
  local highlight_col = col - 1
  if highlight_col < 0 or highlight_col >= #line then
    return
  end

  vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_nr - 1, highlight_col, {
    end_col = highlight_col + 1,
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
  vim.api.nvim_set_hl(0, 'SimplecompleteIndicator', {
    underline = true,
    sp = '#4a9eff',
  })
end

return M
