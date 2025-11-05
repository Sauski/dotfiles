local cmp = require('cmp')

cmp.setup({
  completion = {
    autocomplete = false, -- Manual only
  },
  preselect = cmp.PreselectMode.Item,
  mapping = {
    ['<C-e>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        -- Menu already visible, complete common prefix or navigate
        cmp.complete_common_string()
      else
        -- First press: show menu and complete common prefix
        cmp.complete()
        if cmp.visible() then
          cmp.complete_common_string()
        else
          fallback()
        end
      end
    end, { 'i', 's' }),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<Esc>'] = cmp.mapping.abort(),
  },
  sources = cmp.config.sources({
    { name = 'treesitter' },
  }),
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.disable,
  },
  experimental = {
    ghost_text = false,
  },
})
