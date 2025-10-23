-- init.lua: Main quickbuild module

local builder = require("quickbuild.builder")

local M = {}

-- Setup function
function M.setup(opts)
  opts = opts or {}

  -- Store minimal global config
  M.config = {
    scanner_path = opts.scanner_path,
    verbose = opts.verbose or false,
  }

  -- Load project config from .quickbuild.json
  local project_config = builder.get_project_config()

  if project_config and project_config.auto_build_on_save then
    local file_patterns = project_config.file_patterns or {}
    local debounce_ms = project_config.debounce_ms or 500

    if #file_patterns > 0 then
      vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = file_patterns,
        callback = function()
          M.build({
            debounce_ms = debounce_ms,
          })
        end,
        group = vim.api.nvim_create_augroup("quickbuild_auto", { clear = true }),
      })
    end
  end

  -- Setup VimLeavePre to cancel builds on quit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      M.cancel()
    end,
    group = vim.api.nvim_create_augroup("quickbuild_cleanup", { clear = true }),
  })
end

-- Start build (manual trigger)
function M.build(opts)
  opts = opts or {}

  -- Merge with global config
  if M.config then
    if M.config.scanner_path then
      opts.scanner_path = M.config.scanner_path
    end
    if M.config.verbose ~= nil then
      opts.verbose = M.config.verbose
    end
  end

  -- Manual builds have no debounce by default
  if opts.debounce_ms == nil then
    opts.debounce_ms = 0
  end

  builder.build(opts)
end

-- Cancel active build
function M.cancel()
  builder.cancel()
end

-- Get build status (for status line integration)
function M.get_status()
  return builder.get_status()
end

-- Get metrics
function M.get_metrics()
  return builder.get_metrics()
end

-- Get diagnostic namespace (for custom integrations)
function M.get_namespace()
  return builder.get_namespace()
end

return M
