-- init.lua: Main quickbuild module

local builder = require("quickbuild.builder")
local statusline = require("quickbuild.statusline")

local M = {}

-- Setup function
function M.setup(opts)
  opts = opts or {}

  -- Store minimal global config
  M.config = {
    scanner_path = opts.scanner_path,
    verbose = opts.verbose or false,
  }

  -- Setup status messaging
  statusline.setup({
    enabled = opts.status_messages ~= false,
  })

  -- Always register autocmd on buffer saves
  -- Check at runtime if auto-build is enabled and file matches patterns
  vim.api.nvim_create_autocmd("BufWritePost", {
    callback = function(ev)
      -- Check if current project has auto-build enabled
      local project_config = builder.get_project_config()
      if not project_config or not project_config.auto_build_on_save then
        return  -- Auto-build not enabled for this project
      end

      -- Check if file matches configured patterns
      local file_patterns = project_config.file_patterns or {}
      if #file_patterns == 0 then
        return  -- No patterns configured
      end

      local bufname = vim.api.nvim_buf_get_name(ev.buf)
      local filename = vim.fn.fnamemodify(bufname, ":t")
      local matched = false
      for _, pattern in ipairs(file_patterns) do
        if vim.fn.match(filename, vim.fn.glob2regpat(pattern)) >= 0 then
          matched = true
          break
        end
      end

      if not matched then
        return  -- File doesn't match configured patterns
      end

      -- All checks passed, trigger build
      local debounce_ms = project_config.debounce_ms or 500
      M.build({
        debounce_ms = debounce_ms,
        bufnr = ev.buf,
      })
    end,
    group = vim.api.nvim_create_augroup("quickbuild_auto", { clear = true }),
  })


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
