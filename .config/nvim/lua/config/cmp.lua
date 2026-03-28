local cmp = require('cmp')

-- Flag to track whether to auto-complete common prefix when menu opens
-- Set to true when Ctrl+e is first pressed, consumed by menu_opened event
local want_common = false

--[[
  Event handler for menu_opened

  When the completion menu opens and want_common flag is set:
  1. Clears the flag to prevent repeat triggers
  2. If only one entry, confirm it immediately without showing menu
  3. Otherwise, complete common prefix across all matches
  This implements terminal-style tab completion behavior
--]]
cmp.event:on('menu_opened', function()
  if want_common then
    want_common = false
    vim.schedule(function()
      if cmp.visible() then
        local entries = cmp.get_entries()
        if #entries == 1 then
          cmp.confirm({ select = true })
        else
          cmp.complete_common_string()
        end
      end
    end)
  end
end)

--[[
  nvim-cmp configuration for terminal-style tab completion

  Key behaviors:
  - Manual-only mode: completion only triggers via keybind
  - No preselection: allows complete_common_string() to work
  - Exact prefix matching only: no fuzzy or partial matching
  - Ctrl+e: First press opens menu and completes common prefix
            Subsequent presses continue completing common prefix
  - complete_common_string() requires no item selected (PreselectMode.None)
--]]
cmp.setup({
  completion = {
    autocomplete = false,
  },
  preselect = cmp.PreselectMode.None,
  matching = {
    disallow_fuzzy_matching = true,
    disallow_partial_matching = true,
    disallow_prefix_unmatching = true,
  },
  mapping = {
    --[[
      Terminal-style completion with Ctrl+e

      Behavior:
      - Menu visible: Complete common prefix across all matches
      - Menu not visible: Set flag and open menu, event handler completes prefix
    --]]
    ['<C-e>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.complete_common_string()
      else
        want_common = true
        cmp.complete()
      end
    end, { 'i', 'c' }),
    ['<C-q>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.confirm({ select = true })
      else
        fallback()
      end
    end, { 'i', 'c' }),
    ['<Esc>'] = cmp.mapping.abort(),
  },
  sources = cmp.config.sources({
    { name = 'treesitter' },
    {
      name = 'buffer',
      option = {
        keyword_length = 3,
        keyword_pattern = [[\k\+]],
        get_bufnrs = function()
          return vim.api.nvim_list_bufs()
        end,
        indexing_interval = 200,
        max_indexed_line_length = 40960,
      }
    },
  }),
  experimental = {
    ghost_text = true,
  },
})
