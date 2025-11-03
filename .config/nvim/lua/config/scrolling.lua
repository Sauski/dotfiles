local function get_scroll_amount()
  local s = vim.opt.scroll:get()
  return s > 0 and s or math.floor(vim.api.nvim_win_get_height(0) / 2)
end

local function scroll_down()
  local amount = get_scroll_amount()
  local win = 0
  local buf = 0

  local current_top = vim.fn.line('w0')
  local height = vim.api.nvim_win_get_height(win)
  local total_lines = vim.api.nvim_buf_line_count(buf)

  local max_top = math.max(1, total_lines - height + 1)
  local new_top = math.min(current_top + amount, max_top)

  if new_top == current_top then return end

  vim.api.nvim_win_call(win, function()
    vim.fn.winrestview({ topline = new_top })
  end)

  local so = vim.opt.scrolloff:get()
  local cursor = vim.api.nvim_win_get_cursor(win)
  local cursor_line = cursor[1]

  local safe_line = new_top + so
  if cursor_line < safe_line then
    local new_cursor_line = math.min(safe_line, total_lines)
    vim.api.nvim_win_set_cursor(win, {new_cursor_line, cursor[2]})
  end
end

local function scroll_up()
  local amount = get_scroll_amount()
  local win = 0

  local current_top = vim.fn.line('w0')

  local new_top = math.max(1, current_top - amount)

  if new_top == current_top then return end

  vim.api.nvim_win_call(win, function()
    vim.fn.winrestview({ topline = new_top })
  end)

  local so = vim.opt.scrolloff:get()
  local height = vim.api.nvim_win_get_height(win)
  local cursor = vim.api.nvim_win_get_cursor(win)
  local cursor_line = cursor[1]

  local safe_line = new_top + height - 1 - so
  if cursor_line > safe_line then
    local new_cursor_line = math.max(1, safe_line)
    vim.api.nvim_win_set_cursor(win, {new_cursor_line, cursor[2]})
  end
end

return {
  scroll_down = scroll_down,
  scroll_up = scroll_up,
}
