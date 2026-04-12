-- menu.lua: Native vim completion menu

local M = {}

-- Show completion menu using vim.fn.complete
function M.show(matches)
  if #matches == 0 then return end

  local mode = vim.api.nvim_get_mode().mode
  if mode ~= 'i' then
    return
  end

  local col = vim.fn.col('.')
  local line = vim.api.nvim_get_current_line()
  local before_cursor = line:sub(1, col - 1)
  local start_col = before_cursor:match('.*[^%w_]()') or 1

  -- Save original completeopt
  local saved_completeopt = vim.o.completeopt

  -- Set completeopt to noselect (no auto-selection)
  vim.o.completeopt = 'menu,menuone,noselect'

  -- Restore on next insert leave
  vim.api.nvim_create_autocmd('InsertLeave', {
    once = true,
    callback = function()
      vim.o.completeopt = saved_completeopt
    end,
  })

  -- Call complete with plain string list (vim handles filtering)
  vim.fn.complete(start_col, matches)
end

return M
