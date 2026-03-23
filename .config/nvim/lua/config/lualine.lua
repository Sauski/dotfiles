local function get_normal_bg()
  local normal_hl = vim.api.nvim_get_hl(0, { name = 'Normal' })
  return string.format('#%06x', normal_hl.bg or 0)
end

local function get_tablinefill_bg()
  local tablinefill_hl = vim.api.nvim_get_hl(0, { name = 'TabLineFill' })
  return string.format('#%06x', tablinefill_hl.bg or 0)
end

local trans_sec = { fg = 'NONE', bg = get_tablinefill_bg(), gui = 'italic' }

local trans_mode = {
  a = trans_sec,
  b = trans_sec,
  c = trans_sec,
  x = trans_sec,
  y = trans_sec,
  z = trans_sec,
}

-- Theme for winbar (TabLineFill background)
local transparent_theme = {
  normal = trans_mode,
  insert = trans_mode,
  visual = trans_mode,
  replace = trans_mode,
  command = trans_mode,
  inactive = trans_mode,
}

-- Theme for statusline (Normal background)
local statusline_sec = { fg = 'NONE', bg = get_normal_bg(), gui = 'italic' }
local statusline_mode = {
  a = statusline_sec,
  b = statusline_sec,
  c = statusline_sec,
  x = statusline_sec,
  y = statusline_sec,
  z = statusline_sec,
}

local statusline_theme = {
  normal = statusline_mode,
  insert = statusline_mode,
  visual = statusline_mode,
  replace = statusline_mode,
  command = statusline_mode,
  inactive = statusline_mode,
}

local function smart_path()
  local buf = vim.api.nvim_get_current_buf()
  local buftype = vim.bo[buf].buftype
  local filepath = vim.api.nvim_buf_get_name(buf)

  if buftype == 'terminal' then
    -- If user renamed the buffer with :file <name>
    if not filepath:match("^term://") then
      return vim.fn.fnamemodify(filepath, ":t")
    end

    -- Check for term_title (set by some apps/shells)
    local term_title = vim.b[buf].term_title
    if term_title and term_title ~= "" and not term_title:match("^term://") then
      return term_title
    end

    -- Extract command from term:// host//pid:command
    local cmd = filepath:match(":(.*)$")
    if cmd then
      return vim.fn.fnamemodify(cmd, ":t")
    end

    return 'Terminal'
  end
  
  if filepath == '' then return '[No Name]' end

  local git_root = vim.fs.dirname(vim.fs.find('.git', { path = filepath, upward = true })[1])
  local relative_path
  
  if git_root then
    relative_path = vim.fn.fnamemodify(filepath, ':s?' .. git_root .. '/??')
  else
    relative_path = vim.fn.fnamemodify(filepath, ':~:.')
  end

  local parts = vim.split(relative_path, '/')
  if #parts <= 3 then
    return relative_path
  end

  local result = {}
  for i = 1, #parts - 3 do
    table.insert(result, string.sub(parts[i], 1, 1))
  end
  table.insert(result, parts[#parts - 2])
  table.insert(result, parts[#parts - 1])
  table.insert(result, parts[#parts])

  return table.concat(result, '/')
end

return {
  options = {
    section_separators = '',
    component_separators = '',
    theme = statusline_theme,
  },
  sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {
      {
        function()
          local ok, qb = pcall(require, "quickbuild")
          if not ok then return "" end
          local status = qb.get_status()
          if status.is_running then
            return status.stage
          elseif status.errors > 0 or status.warnings > 0 then
            return string.format("E:%d W:%d", status.errors, status.warnings)
          end
          return ""
        end
      },
      'location',
      'progress'
    },
    lualine_z = {}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
    lualine_z = {}
  },
  -- Move everything to the top of the window with winbar
  winbar = {
    lualine_a = {
      {
        smart_path,
        padding = { left = 1, right = 1 },
        color = { bg = get_normal_bg(), gui = 'italic' }
      }
    },
    lualine_b = {},
    lualine_c = {
      {
        'diagnostics',
        color = { bg = get_normal_bg(), gui = 'italic' }
      }
    },
    lualine_x = {},
    lualine_y = {
      {
        'mode',
        cond = function() return vim.fn.mode() ~= 'n' end,
        separator = '',
        color = { bg = get_normal_bg(), gui = 'italic' }
      },
      { function() return ' ' end }
    },
    lualine_z = {}
  },
  inactive_winbar = {
    lualine_a = {
      {
        smart_path,
        padding = { left = 1, right = 1 },
        color = { bg = get_normal_bg(), gui = 'italic' }
      }
    },
    lualine_b = {},
    lualine_c = {
      {
        'diagnostics',
        color = { bg = get_normal_bg(), gui = 'italic' }
      }
    },
    lualine_x = {},
    lualine_y = {
      { function() return ' ' end }
    },
    lualine_z = {}
  }
}
