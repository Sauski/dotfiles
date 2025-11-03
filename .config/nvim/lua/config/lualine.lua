local function mode_formatter(s)
  return vim.fn.mode() == 'n' and ' ' or s:sub(1,1)
end

local function build_status()
  return require("quickbuild.statusline").get()
end

local normal_bg_num = vim.api.nvim_get_hl(0, { name = 'Normal' }).bg
local normal_bg = normal_bg_num and string.format('#%06x', normal_bg_num) or '#282828'

return {
  options = {
    section_separators = '',
    component_separators = '',
    theme = {
      normal = { a = { bg = normal_bg }, b = { bg = normal_bg }, c = { bg = normal_bg }, x = { bg = normal_bg }, y = { bg = normal_bg }, z = { bg = normal_bg } },
      inactive = { a = { bg = normal_bg }, b = { bg = normal_bg }, c = { bg = normal_bg }, x = { bg = normal_bg }, y = { bg = normal_bg }, z = { bg = normal_bg } },
    }
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
    lualine_a = {
      {
        'filename',
        path = 1,
        padding = { left = 1, right = 1 },
        color = { bg = '#d3869b' }
      }
    },
    lualine_b = {},
    lualine_c = {
      'diagnostics'
    },
    lualine_x = {
      build_status,
      {
        'mode',
        fmt = mode_formatter
      }
    },
    lualine_y = {},
    lualine_z = {}
  },
  inactive_winbar = {
    lualine_a = {
      {
        'filename',
        path = 1,
        padding = { left = 1, right = 1 },
        color = { bg = '#d3869b' }
      }
    },
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
    lualine_z = {}
  }
}
