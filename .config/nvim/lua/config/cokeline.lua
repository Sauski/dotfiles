return {
  buffers = {
    filter_visible = function(buf)
      return vim.fn.bufwinnr(buf.number) <= 0
    end,
  },
  default_hl = {
    fg = function(buf) return buf.is_focused and '#ebdbb2' or '#928374' end,
    bg = function()
      local bg = vim.api.nvim_get_hl(0, { name = 'Normal' }).bg
      return bg and string.format('#%06x', bg) or '#282828'
    end,
  },
  components = {
    {
      text = function(buf)
        return require('cokeline.mappings').is_picking_focus()
          and buf.pick_letter .. ' '
          or ' '
      end,
      fg = '#fabd2f',
      bold = function() return require('cokeline.mappings').is_picking_focus() end,
    },
    {
      text = function(buf) return buf.filename .. ' ' end,
    },
    {
      text = function(buf) return buf.is_modified and '●' or '' end,
      fg = '#fb4934',
    },
  },
}
