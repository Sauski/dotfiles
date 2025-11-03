return {
  config = {
    buffers = {
      filter_visible = function(buf)
        return vim.fn.bufwinnr(buf.number) <= 0
      end,
    },
    default_hl = {
      fg = function(buf) return buf.is_focused and '#ebdbb2' or '#928374' end,
      bg = '#282828',
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
  },

  setup_keymaps = function()
    vim.keymap.set('n', 'S', '<Plug>(cokeline-pick-focus)', { silent = true })

    vim.keymap.set('n', '<leader>x', function()
      local visible = {}
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        visible[buf] = true
      end

      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buf].buflisted and not visible[buf] then
          vim.api.nvim_buf_delete(buf, { force = false })
        end
      end
    end, { silent = true })

    vim.keymap.set({'n', 'i', 'v', 't'}, '<M-{>', function()
      require('cokeline.utils').buf_delete(0)
    end, { noremap = true, silent = true })
  end,
}
