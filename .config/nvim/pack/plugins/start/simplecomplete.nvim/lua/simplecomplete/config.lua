-- config.lua: Default configuration for simplecomplete.nvim

local M = {}

M.defaults = {
  -- Minimum keyword length to trigger completion
  min_keyword_length = 2,

  -- Minimum number of changes (new chars + case diffs) to show indicator
  min_completion_changes = 1,

  -- Debounce time in milliseconds before triggering completion
  debounce_ms = 20,

  -- Source configuration
  sources = {
    -- Which buffers to scan: 'visible', 'all', or function() return {bufnr1, bufnr2} end
    buffers = 'all',

    -- Skip buffers larger than this (in bytes)
    max_buffer_size = 200000,

    -- Maximum unique words to extract per buffer
    max_words_per_buffer = 10000,

    -- File patterns to exclude (optional)
    exclude_patterns = {},
  },

  -- Keymaps
  keymap = {
    accept = '<CR>',
    menu = '<S-CR>',
  },

  -- Filters for completion items
  filters = {
    -- Reject items containing path separators
    no_paths = true,

    -- Reject items ending with file extensions
    no_extensions = true,
  },
}

return M
