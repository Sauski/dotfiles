local M = {}

M.config = {
  file_types = { 'markdown' },  -- Only .md files
  render_modes = { 'n', 'v', 'c' },  -- Render in normal, visual, command modes (not insert)
  anti_conceal = {
    enabled = false  -- Disable showing raw markdown on cursor line
  },
  heading = {
    sign = false,  -- Disable sign column icons
    icons = { '', '', '', '', '', '' },  -- Empty strings to hide # symbols
    backgrounds = { '', '', '', '', '', '' },  -- No backgrounds for headings
  }
}

return M