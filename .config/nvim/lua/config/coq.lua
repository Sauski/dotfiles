return {
  auto_start = 'shut-up',
  keymap = {
    recommended = true,
    manual_complete = '<C-Space>',
  },
  completion = {
    always = false,
    sticky_manual = true,
  },
  match = {
    exact_matches = 2,
    fuzzy_cutoff = 0.7,
    max_results = 10,
  },
  weights = {
    prefix_matches = 2.0,
    edit_distance = 1.5,
  },
  clients = {
    buffers = { enabled = true },
    tree_sitter = { enabled = true },
    paths = { enabled = false },
    snippets = { enabled = false },
    tags = { enabled = false },
    tmux = { enabled = false },
    tabnine = { enabled = false },
    registers = { enabled = false },
  },
}
