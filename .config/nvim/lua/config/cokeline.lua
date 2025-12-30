return {
  buffers = {
    filter_visible = function(buf)
      return vim.fn.bufwinnr(buf.number) <= 0
    end,
    new_buffers_position = require('config.mru').sort_buffers,
  },
  default_hl = {
    fg = function(buf) return buf.is_focused and '#ebdbb2' or '#7c6f64' end,
    bg = function()
      local bg = vim.api.nvim_get_hl(0, { name = 'TabLineFill' }).bg
      return bg and string.format('#%06x', bg) or '#282828'
    end,
  },
  components = {
    {
      text = function(buf)
        if require('cokeline.mappings').is_picking_focus() then
          return buf.pick_letter .. ' '
        end

        local state = require('cokeline.state')
        local visible = state.visible_buffers
        for i, visible_buf in ipairs(visible) do
          if i <= 4 and visible_buf.number == buf.number then
            return i .. '. '
          end
        end
        return '   '
      end,
      fg = function(buf)
        if require('cokeline.mappings').is_picking_focus() then
          return '#fabd2f'
        end
        return buf.is_focused and '#ebdbb2' or '#7c6f64'
      end,
      bold = function() return require('cokeline.mappings').is_picking_focus() end,
    },
    {
      text = function(buf)
        if buf.buftype == 'terminal' then
          local filepath = buf.path
          if not filepath:match("^term://") then
            return vim.fn.fnamemodify(filepath, ":t") .. ' '
          end
          local term_title = vim.b[buf.number].term_title
          if term_title and term_title ~= "" and not term_title:match("^term://") then
            return term_title .. ' '
          end
          local cmd = filepath:match(":(.*)$")
          if cmd then
            return vim.fn.fnamemodify(cmd, ":t") .. ' '
          end
          return 'Terminal '
        end

        local filepath = buf.path
        if filepath == '' or buf.type == 'directory' then return buf.filename .. ' ' end

        local git_root = vim.fs.dirname(vim.fs.find('.git', { path = filepath, upward = true })[1])
        local relative_path
        if git_root then
          relative_path = vim.fn.fnamemodify(filepath, ':s?' .. git_root .. '/??')
        else
          relative_path = vim.fn.fnamemodify(filepath, ':~:.')
        end

        local parts = vim.split(relative_path, '/')
        if #parts <= 1 then
          return relative_path .. ' '
        end

        local result = {}
        for i = 1, #parts - 1 do
          table.insert(result, string.sub(parts[i], 1, 1))
        end
        table.insert(result, parts[#parts])

        return table.concat(result, '/') .. ' '
      end,
    },
    {
      text = function(buf) return buf.is_modified and '● ' or '  ' end,
      fg = '#fb4934',
    },
  },
}
