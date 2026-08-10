return {
  signs = {
    add          = { text = '┃' },
    change       = { text = '┃' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
    untracked    = { text = '┆' },
  },
  signcolumn = false,
  numhl = false,
  linehl = false,
  word_diff = false,
  on_attach = function(bufnr)
    local gitsigns = require('gitsigns')

    local function map(mode, lhs, rhs, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, lhs, rhs, opts)
    end

    -- Navigation
    map('n', ']c', function()
      if vim.wo.diff then
        vim.cmd.normal({']c', bang = true})
      else
        gitsigns.nav_hunk('next')
      end
    end)

    map('n', '[c', function()
      if vim.wo.diff then
        vim.cmd.normal({'[c', bang = true})
      else
        gitsigns.nav_hunk('prev')
      end
    end)

    -- Toggle inline diff visualization
    map('n', '<leader>v', function()
      gitsigns.toggle_signs()
      gitsigns.toggle_linehl()
    end, { silent = true })

    -- Preview hunk in popup (traditional diff view)
    map('n', 'vp', gitsigns.preview_hunk, { silent = true })

    -- Open side-by-side diff in split
    map('n', 'vd', gitsigns.diffthis, { silent = true })

    -- Reset hunk (revert changes)
    map('n', 'vr', gitsigns.reset_hunk, { silent = true })
    map('v', 'vr', gitsigns.reset_hunk, { silent = true })

    -- Select hunk as text object
    map({'o', 'x'}, 'ih', gitsigns.select_hunk)

    -- Diff against HEAD~1, HEAD~2, HEAD~3
    map('n', 'v1', function() gitsigns.change_base('HEAD~1', true) end, { silent = true })
    map('n', 'v2', function() gitsigns.change_base('HEAD~2', true) end, { silent = true })
    map('n', 'v3', function() gitsigns.change_base('HEAD~3', true) end, { silent = true })

    -- Diff against upstream
    map('n', 'vu', function() gitsigns.change_base('@{u}', true) end, { silent = true })

    -- Reset to default (unstaged changes)
    map('n', 'v0', function() gitsigns.change_base(nil, true) end, { silent = true })
  end,
}
