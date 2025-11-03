local function build_status()
  return require("quickbuild.statusline").get()
end

-- 1. Define a single "transparent" section
-- 'NONE' tells Neovim to use the default editor background
local trans_sec = { fg = 'NONE', bg = 'NONE' }

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
      }  
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
      'diagnostics',
    },
    lualine_x = {},
    lualine_y = {},
    lualine_z = {}
  }
}
