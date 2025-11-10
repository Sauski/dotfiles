-- coalesce.lua: Group diagnostics by location and merge messages

local M = {}

local function severity_priority(severity)
  local priorities = {
    [vim.diagnostic.severity.ERROR] = 4,
    [vim.diagnostic.severity.WARN] = 3,
    [vim.diagnostic.severity.INFO] = 2,
    [vim.diagnostic.severity.HINT] = 1,
  }
  return priorities[severity] or 0
end

local function severity_string(severity)
  if severity == vim.diagnostic.severity.ERROR then
    return "error"
  elseif severity == vim.diagnostic.severity.WARN then
    return "warning"
  elseif severity == vim.diagnostic.severity.INFO then
    return "info"
  elseif severity == vim.diagnostic.severity.HINT then
    return "hint"
  end
  return "error"
end

-- Coalesce diagnostics by location
function M.coalesce(diagnostics)
  local by_location = {}

  for _, diag in ipairs(diagnostics) do
    local key = string.format("%s:%d:%d", diag.file, diag.lnum, diag.col)

    if by_location[key] then
      local existing = by_location[key]

      -- Check if message already exists
      local found = false
      for _, msg in ipairs(existing.messages) do
        if msg == diag.message then
          found = true
          break
        end
      end

      if not found then
        table.insert(existing.messages, diag.message)
      end

      -- Keep highest severity
      if severity_priority(diag.severity) > severity_priority(existing.severity) then
        existing.severity = diag.severity
      end
    else
      by_location[key] = {
        file = diag.file,
        lnum = diag.lnum,
        col = diag.col,
        severity = diag.severity,
        source = diag.source,
        messages = { diag.message },
      }
    end
  end

  -- Convert back to array with severity-prefixed messages
  local result = {}
  for _, coalesced in pairs(by_location) do
    local severity_prefix = severity_string(coalesced.severity)
    local prefixed_messages = {}

    for _, msg in ipairs(coalesced.messages) do
      table.insert(prefixed_messages, msg)
    end

    table.insert(result, {
      file = coalesced.file,
      lnum = coalesced.lnum,
      col = coalesced.col,
      severity = coalesced.severity,
      source = coalesced.source,
      -- Use " | " not "\n" - newlines break fzf-lua preview/jump parser
      message = severity_prefix .. ": " .. table.concat(prefixed_messages, " | "),
      user_data = {
        filename = coalesced.file,
      },
    })
  end

  return result
end

return M
