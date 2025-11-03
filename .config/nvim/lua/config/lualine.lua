local function mode_formatter(s)
  return vim.fn.mode() == 'n' and ' ' or s:sub(1,1)
end

local function build_status()
  return require("quickbuild.statusline").get()
end

return {
  options = {
    section_separators = '',
    component_separators = ''
  },
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
  winbar = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {
      {
        'mode',
        fmt = mode_formatter
      },
      {
        'filename',
        padding = { left = 1, right = 1 }
      },
      'diagnostics'
    },
    lualine_x = {
      build_status
    },
    lualine_y = {},
    lualine_z = {}
  },
  inactive_winbar = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {
      {
        'filename',
        padding = { left = 1, right = 1 }
      }
    },
    lualine_x = {},
    lualine_y = {},
    lualine_z = {}
  }
}
