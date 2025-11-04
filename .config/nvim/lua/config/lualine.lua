local function build_status()
  return require("quickbuild.statusline").get()
end

local function get_normal_bg()
  local normal_hl = vim.api.nvim_get_hl(0, { name = 'Normal' })
  return string.format('#%06x', normal_hl.bg or 0)
end

local trans_sec = { fg = 'NONE', bg = get_normal_bg() }

local trans_mode = {
  a = trans_sec,
  b = trans_sec,
  c = trans_sec,
  x = trans_sec,
  y = trans_sec,
  z = trans_sec,
}

-- 3. Create the theme by applying the transparent mode to ALL states
local transparent_theme = {
  normal = trans_mode,
  insert = trans_mode,
  visual = trans_mode,
  replace = trans_mode,
  command = trans_mode,
  inactive = trans_mode,
}

return {
  options = {
    section_separators = '!',
    component_separators = '|',
    theme = transparent_theme,
  },
  -- Clear out the bottom bar sections
  sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
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
        'filename',
        path = 4, -- Filename & Parent
        padding = { left = 1, right = 1 },
      }
    },
    lualine_b = {},
    lualine_c = {
      'diagnostics'
    },
    lualine_x = {},
    lualine_y = {
       build_status,
      {
        'mode',
        cond = function() return vim.fn.mode() ~= 'n' end,
        separator = ''
      },
      { function() return ' ' end }
    },
    lualine_z = {}
  },
  inactive_winbar = {
    lualine_a = {
      {
        'filename',
        path = 4, -- Filename & Parent
        padding = { left = 1, right = 1 },
      }
    },
    lualine_b = {},
    lualine_c = {
      'diagnostics'
    },
    lualine_x = {},
    lualine_y = {
      { function() return ' ' end }
    },
    lualine_z = {}
  }
}
