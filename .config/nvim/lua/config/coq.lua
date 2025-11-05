return {
  auto_start = 'shut-up',
  keymap = {
    recommended = true,
    manual_complete = '<C-e>',
    pre_select = true,
  },
  completion = {
    always = false,
  },
  display = {
    ghost_text = {
      enabled = true,
    },
    preview = {
      enabled = false,
    },
  },
  match = {
    exact_matches = 2,
    fuzzy_cutoff = 0.7,
  },
  weights = {
    prefix_matches = 2.0,
    edit_distance = 1.5,
  },
  clients = {
    buffers = { enabled = false },
    tree_sitter = { enabled = true },
    paths = { enabled = false },
    snippets = { enabled = false },
    tags = { enabled = false },
    tmux = { enabled = false },
    tabnine = { enabled = false },
    registers = { enabled = false },
    lsp = { enabled = false },
  },
}
