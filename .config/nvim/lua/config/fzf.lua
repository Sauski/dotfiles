local actions = require('fzf-lua.actions')

return {
  keymap = {
    builtin = {
      ["<C-d>"] = "preview-page-down",
      ["<C-u>"] = "preview-page-up",
    },
  },
  oldfiles = {
    include_current_session = true,
  },
  lines = {
    actions = {
      ["default"] = actions.buf_switch_or_edit,
    },
  },
  blines = {
    actions = {
      ["default"] = actions.buf_switch_or_edit,
    },
  },
}
