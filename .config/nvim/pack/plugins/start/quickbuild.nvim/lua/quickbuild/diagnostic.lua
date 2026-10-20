-- diagnostic.lua: Parse scanner output and publish to vim.diagnostic

local M = {}

-- Parse single diagnostic line from scanner
-- Format: file:line:col:severity:message
-- Uses regex matching to handle Windows paths (C:/) correctly
function M.parse_line(line, git_root)
  if not line or line == "" then
    return nil
  end

  local file, line_str, col_str, severity, message = line:match("^(.+):(%d+):(%d+):(%w+):(.+)$")

  if not file then
    return nil
  end

  local line_num = tonumber(line_str)
  local col_num = tonumber(col_str)

  if not line_num or not col_num then
    return nil
  end

  -- Map severity to vim.diagnostic severity
  local severity_map = {
    error = vim.diagnostic.severity.ERROR,
    warning = vim.diagnostic.severity.WARN,
    info = vim.diagnostic.severity.INFO,
    hint = vim.diagnostic.severity.HINT,
  }

  local vim_severity = severity_map[severity:lower()] or vim.diagnostic.severity.ERROR

  -- Handle project-level diagnostics
  if file == "PROJECT" then
    return {
      file = "PROJECT",
      lnum = 0,
      col = 0,
      end_lnum = 0,
      end_col = 0,
      severity = vim_severity,
      message = message,
      is_project_level = true,
    }
  end

  return {
    file = file,
    lnum = line_num - 1,  -- 0-indexed
    col = col_num - 1,    -- 0-indexed
    end_lnum = line_num - 1,
    end_col = col_num - 1,
    severity = vim_severity,
    message = message,
  }
end

-- Group diagnostics by file
function M.group_by_file(diagnostics)
  local grouped = {}
  local project_diags = {}

  for _, diag in ipairs(diagnostics) do
    if diag.is_project_level then
      table.insert(project_diags, {
        lnum = 0,
        col = 0,
        end_lnum = 0,
        end_col = 0,
        severity = diag.severity,
        message = diag.message,
        source = diag.source,
      })
    else
      local file = diag.file
      if not grouped[file] then
        grouped[file] = {}
      end

      table.insert(grouped[file], {
        lnum = diag.lnum,
        col = diag.col,
        end_lnum = diag.end_lnum,
        end_col = diag.end_col,
        severity = diag.severity,
        message = diag.message,
        source = diag.source,
      })
    end
  end

  return grouped, project_diags
end

-- Publish diagnostics to vim.diagnostic API
function M.publish(diagnostics, namespace)
  local grouped, project_diags = M.group_by_file(diagnostics)

  -- Clear all existing diagnostics first
  vim.diagnostic.reset(namespace)

  -- Set diagnostics for each buffer
  for file, file_diagnostics in pairs(grouped) do
    local bufnr = vim.fn.bufnr(file, true)
    vim.diagnostic.set(namespace, bufnr, file_diagnostics, {})
  end

  -- Handle project-level diagnostics
  if #project_diags > 0 then
    local bufname = ".quickbuild-diagnostics"
    local bufnr = vim.fn.bufnr(bufname)

    if bufnr == -1 then
      bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, bufname)
      vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
      vim.api.nvim_buf_set_option(bufnr, "bufhidden", "hide")
      vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
    end

    local lines = {}
    for _, diag in ipairs(project_diags) do
      local severity_name = vim.diagnostic.severity[diag.severity] or "ERROR"
      table.insert(lines, string.format("[%s] %s", severity_name, diag.message))
    end

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.diagnostic.set(namespace, bufnr, project_diags, {})
  end
end

-- Clear all diagnostics
function M.clear(namespace)
  vim.diagnostic.reset(namespace)
end

-- Move a buffer's diagnostics into the stale namespace
function M.mark_stale(bufnr, namespace, stale_namespace)
  local current = vim.diagnostic.get(bufnr, { namespace = namespace })
  if #current == 0 then
    return
  end

  local stale = vim.diagnostic.get(bufnr, { namespace = stale_namespace })
  vim.list_extend(stale, current)
  vim.diagnostic.set(stale_namespace, bufnr, stale, {})
  vim.diagnostic.reset(namespace, bufnr)
end

local stale_sign_hl = {
  [vim.diagnostic.severity.ERROR] = "QuickbuildStaleError",
  [vim.diagnostic.severity.WARN] = "QuickbuildStaleWarn",
  [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
  [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
}

-- Define stale highlight groups (re-run on ColorScheme)
function M.define_stale_highlights()
  vim.api.nvim_set_hl(0, "QuickbuildStaleError", { fg = "#ff8c00", default = true })
  vim.api.nvim_set_hl(0, "QuickbuildStaleWarn", { fg = "#f0e68c", default = true })
end

-- Register sign handler for the stale namespace (built-in signs use fixed DiagnosticSign* colors)
function M.setup_stale(stale_namespace)
  local sign_namespace = vim.api.nvim_create_namespace("quickbuild_stale_signs")

  -- Registered handlers run for every namespace, so both callbacks filter on stale_namespace
  vim.diagnostic.handlers.quickbuild_stale = {
    show = function(namespace, bufnr, diagnostics)
      -- Unloaded buffers are not clamped to their line count (matches built-in signs)
      if namespace ~= stale_namespace or not vim.api.nvim_buf_is_loaded(bufnr) then
        return
      end
      vim.api.nvim_buf_clear_namespace(bufnr, sign_namespace, 0, -1)
      for _, diag in ipairs(diagnostics) do
        vim.api.nvim_buf_set_extmark(bufnr, sign_namespace, diag.lnum, 0, {
          sign_text = vim.diagnostic.severity[diag.severity]:sub(1, 1),
          sign_hl_group = stale_sign_hl[diag.severity],
          priority = 10,
        })
      end
    end,
    hide = function(namespace, bufnr)
      if namespace == stale_namespace and vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_clear_namespace(bufnr, sign_namespace, 0, -1)
      end
    end,
  }

  vim.diagnostic.config({ signs = false, underline = false }, stale_namespace)
  M.define_stale_highlights()
end

return M
