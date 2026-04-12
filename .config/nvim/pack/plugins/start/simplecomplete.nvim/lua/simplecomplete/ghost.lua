-- ghost.lua: Ghost text display using extmarks

local M = {}

-- Namespace for extmarks
local ns_id = vim.api.nvim_create_namespace('simplecomplete')

-- Current ghost text state
local current_ghost = nil

-- Show ghost text at cursor position
function M.show(bufnr, line_nr, col, text, config)
  if not text or #text == 0 then
    return
  end

  if not config.ghost_text.enabled then
    return
  end

  -- Clear any existing ghost text
  M.hide(bufnr)

  -- Create extmark with virtual text
  local ok, mark_id = pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_id, line_nr - 1, col, {
    virt_text = {{text, config.ghost_text.hl_group}},
    virt_text_pos = 'inline',
    hl_mode = 'combine',
  })

  if ok then
    current_ghost = {
      bufnr = bufnr,
      line_nr = line_nr,
      col = col,
      text = text,
      mark_id = mark_id,
    }
  end
end

-- Hide ghost text
function M.hide(bufnr)
  if current_ghost and current_ghost.bufnr == bufnr then
    pcall(vim.api.nvim_buf_del_extmark, bufnr, ns_id, current_ghost.mark_id)
    current_ghost = nil
  end
end

-- Clear all ghost text in buffer
function M.clear_buffer(bufnr)
  pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns_id, 0, -1)
  if current_ghost and current_ghost.bufnr == bufnr then
    current_ghost = nil
  end
end

-- Get current ghost text info
function M.get_current()
  return current_ghost
end

return M
