local cmp = require('cmp')

-- Flag to track whether to auto-complete common prefix when menu opens
-- Set to true when Ctrl+e is first pressed, consumed by menu_opened event
local want_common = false

--[[
  Event handler for menu_opened

  When the completion menu opens and want_common flag is set:
  1. Clears the flag to prevent repeat triggers
  2. Schedules complete_common_string() to run after menu is fully rendered
  3. This implements terminal-style tab completion: first press completes common prefix
--]]
cmp.event:on('menu_opened', function()
  if want_common then
    want_common = false
    vim.schedule(function()
      if cmp.visible() then
        cmp.complete_common_string()
      end
    end)
  end
end)

--[[
  nvim-cmp configuration for terminal-style tab completion

  Key behaviors:
  - Manual-only mode: completion only triggers via keybind
  - No preselection: allows complete_common_string() to work
  - Ctrl+e: First press opens menu and completes common prefix
            Subsequent presses continue completing common prefix
  - complete_common_string() requires no item selected (PreselectMode.None)
--]]
cmp.setup({
  completion = {
    autocomplete = false,
  },
  preselect = cmp.PreselectMode.None,
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
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<Esc>'] = cmp.mapping.abort(),
  },
  sources = cmp.config.sources({
    { name = 'treesitter' },
  }),
  experimental = {
    ghost_text = true,
  },
})
