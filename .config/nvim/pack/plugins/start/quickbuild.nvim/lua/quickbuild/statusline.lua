-- statusline.lua: Status line integration

local M = {}

local config = {
  enabled = true,
  completion_duration_ms = 2000,
}

local status = {
  state = "idle",  -- idle | building | success | failed
  stage = nil,
  completion_timer = nil,
}

function M.setup(opts)
  opts = opts or {}
  config.enabled = opts.enabled ~= false
  config.completion_duration_ms = opts.completion_duration_ms or 2000
end

function M.set_building(stage_name)
  if not config.enabled then
    return
  end

  if status.completion_timer then
    vim.loop.timer_stop(status.completion_timer)
    status.completion_timer:close()
    status.completion_timer = nil
  end

  status.state = "building"
  status.stage = stage_name
  vim.schedule(function()
    vim.cmd("redrawstatus")
  end)
end

function M.set_completed(success)
  if not config.enabled then
    return
  end

  status.state = success and "success" or "failed"
  status.stage = nil
  vim.schedule(function()
    vim.cmd("redrawstatus")
  end)

  -- Reset to idle after duration
  status.completion_timer = vim.loop.new_timer()
  status.completion_timer:start(config.completion_duration_ms, 0, vim.schedule_wrap(function()
    status.state = "idle"
    status.stage = nil
    vim.cmd("redrawstatus")
    if status.completion_timer then
      status.completion_timer:close()
      status.completion_timer = nil
    end
  end))
end

function M.set_idle()
  if not config.enabled then
    return
  end

  if status.completion_timer then
    vim.loop.timer_stop(status.completion_timer)
    status.completion_timer:close()
    status.completion_timer = nil
  end

  status.state = "idle"
  status.stage = nil
  vim.schedule(function()
    vim.cmd("redrawstatus")
  end)
end

function M.get()
  if not config.enabled then
    return ""
  end

  if status.state == "building" then
    return status.stage and ("Building: " .. status.stage) or "Building"
  elseif status.state == "success" then
    return "Build OK"
  elseif status.state == "failed" then
    return "Build Failed"
  end

  return ""
end

return M
