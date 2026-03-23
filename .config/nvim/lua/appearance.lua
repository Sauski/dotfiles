vim.opt.background = 'dark'
vim.g.gruvbox_material_background = 'medium'
vim.g.gruvbox_material_better_performance = 1
vim.cmd('colorscheme gruvbox-material')

vim.api.nvim_set_hl(0, "@type.builtin", { fg = "#e78a4e" })

vim.g.neovide_scroll_animation_length = 0.3
vim.g.neovide_cursor_animation_length = 0.1
vim.g.neovide_cursor_animate_command_line = false
