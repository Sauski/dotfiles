-- statusline.lua: Status messaging via command window

local M = {}

local config = {
  enabled = true,
  completion_duration_ms = 2000,
}

local clear_timer = nil

function M.setup(opts)
  opts = opts or {}
  config.enabled = opts.enabled ~= false
  config.completion_duration_ms = opts.completion_duration_ms or 2000
end

function M.set_building(stage_name)
  if not config.enabled then
    return
  end

  -- Cancel any pending clear
  if clear_timer then
    vim.loop.timer_stop(clear_timer)
    clear_timer:close()
    clear_timer = nil
  end

  vim.schedule(function()
    vim.cmd.echomsg(string.format('"[quickbuild] Building: %s"', stage_name))
  end)
end

function M.set_completed(success)
  if not config.enabled then
    return
  end

  -- Cancel any pending clear
  if clear_timer then
    vim.loop.timer_stop(clear_timer)
    clear_timer:close()
    clear_timer = nil
  end

  vim.schedule(function()
    if success then
      vim.cmd.echomsg('"[quickbuild] Build OK"')
    else
      vim.cmd.echohl("ErrorMsg")
      vim.cmd.echomsg('"[quickbuild] Build Failed"')
      vim.cmd.echohl("None")
    end
  end)

  -- Clear message after duration
  clear_timer = vim.loop.new_timer()
  clear_timer:start(config.completion_duration_ms, 0, vim.schedule_wrap(function()
    vim.cmd.echo('""')
    if clear_timer then
      clear_timer:close()
      clear_timer = nil
    end
  end))
end

function M.set_idle()
  -- Cancel any pending clear
  if clear_timer then
    vim.loop.timer_stop(clear_timer)
    clear_timer:close()
    clear_timer = nil
  end
end

return M
