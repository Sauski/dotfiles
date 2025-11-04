-- statusline.lua: Status messaging via command window

local M = {}

local config = {
  enabled = true,
}

function M.setup(opts)
  opts = opts or {}
  config.enabled = opts.enabled ~= false
end

function M.set_building(stage_name)
  if not config.enabled then
    return
  end

  vim.schedule(function()
    vim.cmd.echomsg(string.format('"[quickbuild] Building: %s"', stage_name))
  end)
end

function M.set_completed(success)
  if not config.enabled then
    return
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
end

function M.set_idle()
  -- No-op for command window (no persistent state to clear)
end

return M
