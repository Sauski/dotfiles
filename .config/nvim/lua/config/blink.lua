return {
  fuzzy = {
    implementation = 'rust',
    prebuilt_binaries = {
      ignore_version_mismatch = true,
    },
  },
  completion = {
    ghost_text = { enabled = true },
    menu = { auto_show = false },
    keyword = {
      range = 'prefix',
    },
    trigger = {
      show_on_backspace = false,
      show_on_backspace_in_keyword = false,
      show_on_backspace_after_accept = false,
      show_on_backspace_after_insert_enter = false,
    },
  },
  sources = {
    default = { 'buffer' },
    min_keyword_length = 4,
    providers = {
      buffer = {
        opts = {
          get_bufnrs = vim.api.nvim_list_bufs
        }
      }
    }
  },
  keymap = {
    preset = 'default',
    ['<CR>'] = { 'accept', 'fallback' },
  }
}
