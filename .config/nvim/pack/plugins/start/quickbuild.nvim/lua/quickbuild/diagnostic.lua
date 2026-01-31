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

  for _, diag in ipairs(diagnostics) do
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

  return grouped
end

-- Publish diagnostics to vim.diagnostic API
function M.publish(diagnostics, namespace)
  local grouped = M.group_by_file(diagnostics)

  -- Clear all existing diagnostics first
  vim.diagnostic.reset(namespace)

  -- Set diagnostics for each buffer
  for file, file_diagnostics in pairs(grouped) do
    local bufnr = vim.fn.bufnr(file, true)  -- Create buffer if doesn't exist
    vim.diagnostic.set(namespace, bufnr, file_diagnostics, {})
  end
end

-- Clear all diagnostics
function M.clear(namespace)
  vim.diagnostic.reset(namespace)
end

return M
